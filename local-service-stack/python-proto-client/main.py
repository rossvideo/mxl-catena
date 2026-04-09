import os
import time
import grpc
from protos import param_pb2, service_pb2_grpc  # compiled at startup into /app/protos




# echo that we are starting the configuration
print("Starting Catena device configuration...")

def _normalize_oid(oid: str) -> str:
    return oid if oid.startswith("/") else f"/{oid}"


def _get_slot(stub: service_pb2_grpc.CatenaServiceStub) -> int:
    slots = stub.GetPopulatedSlots(param_pb2.Empty(), timeout=5).slots
    return slots[0] if slots else 0


def runCommand(targetURL, targetPort, command):
    normalized_command = _normalize_oid(command)
    print(f"RPC ExecuteCommand -> {normalized_command}")
    with grpc.insecure_channel(f"{targetURL}:{targetPort}") as channel:
        stub = service_pb2_grpc.CatenaServiceStub(channel)
        slot = _get_slot(stub)
        payload = param_pb2.ExecuteCommandPayload(
            slot=slot,
            oid=normalized_command,
            value=param_pb2.Value(empty_value=param_pb2.Empty()),
            respond=True,
        )
        response_count = 0
        for response in stub.ExecuteCommand(payload, timeout=120):
            response_count += 1
            if response.WhichOneof("kind") == "exception":
                raise RuntimeError(response.exception.details or "Command execution failed")
        print(f"RPC ExecuteCommand <- {normalized_command} ({response_count} response message(s))")


def setIntParam(targetURL, targetPort, OID, value):
    normalized_oid = _normalize_oid(OID)
    print(f"RPC SetValue[int] -> {normalized_oid} = {int(value)}")
    with grpc.insecure_channel(f"{targetURL}:{targetPort}") as channel:
        stub = service_pb2_grpc.CatenaServiceStub(channel)
        slot = _get_slot(stub)
        payload = param_pb2.SingleSetValuePayload(
            slot=slot,
            value=param_pb2.SetValuePayload(
                oid=normalized_oid,
                value=param_pb2.Value(int32_value=int(value)),
            ),
        )
        stub.SetValue(payload, timeout=10)
    print(f"RPC SetValue[int] <- {normalized_oid} (ok)")


def setStringParam(targetURL, targetPort, OID, value):
    normalized_oid = _normalize_oid(OID)
    print(f"RPC SetValue[string] -> {normalized_oid} = {value}")
    with grpc.insecure_channel(f"{targetURL}:{targetPort}") as channel:
        stub = service_pb2_grpc.CatenaServiceStub(channel)
        slot = _get_slot(stub)
        payload = param_pb2.SingleSetValuePayload(
            slot=slot,
            value=param_pb2.SetValuePayload(
                oid=normalized_oid,
                value=param_pb2.Value(string_value=str(value)),
            ),
        )
        stub.SetValue(payload, timeout=10)
    print(f"RPC SetValue[string] <- {normalized_oid} (ok)")


def getParam(targetURL, targetPort, OID):
    normalized_oid = _normalize_oid(OID)
    print(f"RPC GetValue -> {normalized_oid}")
    with grpc.insecure_channel(f"{targetURL}:{targetPort}") as channel:
        stub = service_pb2_grpc.CatenaServiceStub(channel)
        slot = _get_slot(stub)
        value = stub.GetValue(
            param_pb2.GetValuePayload(slot=slot, oid=normalized_oid),
            timeout=10,
        )

    kind = value.WhichOneof("kind")
    if kind == "string_value":
        result = value.string_value
        print(f"RPC GetValue <- {normalized_oid} = {result}")
        return result
    if kind == "int32_value":
        result = str(value.int32_value)
        print(f"RPC GetValue <- {normalized_oid} = {result}")
        return result
    if kind == "float32_value":
        result = str(value.float32_value)
        print(f"RPC GetValue <- {normalized_oid} = {result}")
        return result
    if kind == "empty_value":
        print(f"RPC GetValue <- {normalized_oid} = ''")
        return ""
    if kind is None:
        print(f"RPC GetValue <- {normalized_oid} = '' (unset)")
        return ""
    result = str(getattr(value, kind))
    print(f"RPC GetValue <- {normalized_oid} = {result}")
    return result

targetPort = 7248
time.sleep(5)  # wait for the container to be ready
print("Setting parameters on the device...")
setStringParam("host.docker.internal", targetPort, "/clip_store", "/data")
setStringParam("host.docker.internal", targetPort, "/websocket_url", os.getenv("WEBSOCKET_URL", "ws://host.docker.internal:8180/interface"))
time.sleep(1)
runCommand("host.docker.internal", targetPort, "/start_session")
while getParam("host.docker.internal", targetPort, "/status") != "1":
    print("Waiting for device to be ready...")
    time.sleep(1)
runCommand("host.docker.internal", targetPort, "/play_clip")
# print("Setting NDI to MXL configuration...")
targetPort = 7269

setStringParam("host.docker.internal", targetPort, "/ndi_source_ips", os.getenv("NDI_SOURCE_IPS", "10.0.1.74"))
setStringParam("host.docker.internal", targetPort, "/selected_ndi_source", os.getenv("SELECTED_NDI_SOURCE", ""))
setStringParam("host.docker.internal", targetPort, "/create_flow/domain", os.getenv("MXL_DOMAIN","/dev/shm"))
setStringParam("host.docker.internal", targetPort, "/create_flow/id", os.getenv("NDI2MXL_UUID","19736e97-a32d-40b3-a2b1-4aa0cf4a5f10"))
setStringParam("host.docker.internal", targetPort, "/create_flow/label", os.getenv("FLOW_LABEL", "NDI to MXL Converter"))
setIntParam("host.docker.internal", targetPort, "/create_flow/width", int(os.getenv("FLOW_WIDTH", "1920")))
setIntParam("host.docker.internal", targetPort, "/create_flow/height", int(os.getenv("FLOW_HEIGHT", "1080")))
setIntParam("host.docker.internal", targetPort, "/create_flow/numerator", int(os.getenv("FLOW_NUMERATOR", "60000")))
setIntParam("host.docker.internal", targetPort, "/create_flow/denominator", int(os.getenv("FLOW_DENOMINATOR", "1001")))
time.sleep(1)
runCommand("host.docker.internal", targetPort, "/start")
while getParam("host.docker.internal", targetPort, "/status") != "Running":
    print("Waiting for device to be ready...")
    time.sleep(1)
# echo that its done and stop the container
targetPort = 7254
setStringParam("host.docker.internal", targetPort, "/domains", "/dev/shm/ross")
runCommand("host.docker.internal", targetPort, "/start")
while getParam("host.docker.internal", targetPort, "/status") != "Running":
    print("Waiting for device to be ready...")
    time.sleep(1)

print("Configuration complete. Stopping container...")
# send the stop_command to the device to stop it

exit(0)