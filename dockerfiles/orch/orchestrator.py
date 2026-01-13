import asyncio
import docker
import grpc

import pb.param_pb2
import pb.service_pb2_grpc

start_order = [
    "ts2mxl",
    "mxl2ndi",
]

client = docker.from_env()


async def wait_for_service(service_name):
    print(f"Waiting for service {service_name} to be started...")
    container_name = f"mxl-demo-{service_name}-1"
    for _ in range(10):
        await asyncio.sleep(1)
        try:
            service = client.containers.get(container_name)
            service.reload()
            if service.status == "running":
                print(f"Service {service_name} is running.")
                return
        except docker.errors.NotFound:
            pass
    raise Exception(f"Service {service_name} did not start in time.")


async def main():
    for service in start_order:
        await wait_for_service(service)

        # Give some time for the service to be ready to accept gRPC connections
        await asyncio.sleep(2)

        channel = grpc.insecure_channel(f"{service}:6254")
        stub = pb.service_pb2_grpc.CatenaServiceStub(channel)

        request = stub.GetValue(pb.param_pb2.GetValuePayload(slot=0, oid="/status"))
        if request.string_value != "Stopped":
            continue
        request = stub.ExecuteCommand(
            pb.param_pb2.ExecuteCommandPayload(
                slot=0,
                oid="/start",
                value=pb.param_pb2.Value(empty_value=pb.param_pb2.Empty()),
                respond=False,
            )
        )
        print(f"Started service {service}.")


if __name__ == "__main__":
    asyncio.run(main())
