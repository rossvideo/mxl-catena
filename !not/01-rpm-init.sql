--
-- PostgreSQL database dump

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: evaluate_licenses(bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.evaluate_licenses(infinite_count bigint, finite_count bigint, finite_sum bigint) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF infinite_count > 0 AND finite_count = 0 THEN
        RETURN GET_INFINITE_NUM();
    ELSIF finite_count > 0 AND infinite_count = 0 THEN
        RETURN finite_sum;
    ELSIF infinite_count > 0 AND finite_count > 0 THEN
        RETURN -1;
    ELSE 
        RETURN 0;
    END IF;
END;$$;


ALTER FUNCTION public.evaluate_licenses(infinite_count bigint, finite_count bigint, finite_sum bigint) OWNER TO postgres;

--
-- Name: evaluate_used_licenses(bigint, bigint, bigint, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.evaluate_used_licenses(infinite_count bigint, finite_count bigint, finite_sum bigint, infinite_sum bigint) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF infinite_count > 0 AND finite_count = 0 THEN
        RETURN infinite_sum;
    ELSIF finite_count > 0 AND infinite_count = 0 THEN
        RETURN finite_sum;
    ELSIF infinite_count > 0 AND finite_count > 0 THEN
        RETURN -1;
    ELSE 
        RETURN 0;
    END IF;
END;$$;


ALTER FUNCTION public.evaluate_used_licenses(infinite_count bigint, finite_count bigint, finite_sum bigint, infinite_sum bigint) OWNER TO postgres;

--
-- Name: get_checked_out_status(character varying, boolean, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_checked_out_status(checked_out_hardware_id character varying, activated boolean, licensing_mode character varying, activated_offline boolean) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF checked_out_hardware_id IS NOT NULL THEN
        RETURN 'Yes';
    ELSIF licensing_mode = 'STATIC' AND activated THEN
        RETURN 'Yes';
    ELSIF NOT activated THEN
        RETURN 'No';
    ELSIF activated_offline THEN
        RETURN 'Yes';
    ELSE
        RETURN 'No';
    END IF;
END;$$;


ALTER FUNCTION public.get_checked_out_status(checked_out_hardware_id character varying, activated boolean, licensing_mode character varying, activated_offline boolean) OWNER TO postgres;

--
-- Name: get_hardware_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_hardware_id() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
  RETURN current_setting('rpm.hardware_id', true);  -- true = return NULL if not set
END;
$$;


ALTER FUNCTION public.get_hardware_id() OWNER TO postgres;

--
-- Name: get_infinite_num(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_infinite_num() RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  infinite CONSTANT int := 999999999;
BEGIN
  RETURN infinite;
END;
$$;


ALTER FUNCTION public.get_infinite_num() OWNER TO postgres;

--
-- Name: license_analytics_by_feature_get_host_summary(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.license_analytics_by_feature_get_host_summary(input_product_key character varying, input_product_id integer, input_feature_id integer) RETURNS TABLE("ID" bigint, "HOST_INFO" text, "USED" bigint, "PRODUCT_NAME" character varying, "FEATURE_NAME" character varying, "PRODUCT_KEY" character varying, "HOST_NAME" character varying, "HOST_IP_ADDRESS" character varying, "PRODUCT_ID" bigint, "FEATURE_ID" bigint)
    LANGUAGE plpgsql
    AS $$BEGIN RETURN QUERY SELECT * FROM LICENSE_ANALYTICS_BY_FEATURE_HOST_SUMMARY AS V WHERE V."PRODUCT_KEY" = INPUT_PRODUCT_KEY AND V."PRODUCT_ID" = INPUT_PRODUCT_ID AND V."FEATURE_ID" = INPUT_FEATURE_ID; END;$$;


ALTER FUNCTION public.license_analytics_by_feature_get_host_summary(input_product_key character varying, input_product_id integer, input_feature_id integer) OWNER TO postgres;

--
-- Name: license_analytics_by_feature_get_product_key_summary(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.license_analytics_by_feature_get_product_key_summary(input_product_id integer, input_feature_id integer) RETURNS TABLE("PRODUCT_KEY" character varying, "LICENSED_TO" character varying, "TOTAL" bigint, "USED" integer, "AVAILABLE" bigint, "EXPIRED" bigint, "USAGE" numeric, "PRODUCT_NAME" character varying, "FEATURE_NAME" character varying, "CHECKED_OUT" character varying, "CHECKED_OUT_HARDWARE_ID" character varying, "PRODUCT_ID" bigint, "FEATURE_ID" bigint)
    LANGUAGE plpgsql
    AS $$BEGIN RETURN QUERY SELECT L."PRODUCT_KEY", L."LICENSED_TO", L."TOTAL", L."USED", L."AVAILABLE", L."EXPIRED", L."USAGE", L."PRODUCT_NAME", L."FEATURE_NAME", L."CHECKED_OUT", L."CHECKED_OUT_HARDWARE_ID",L."PRODUCT_ID",L."FEATURE_ID" FROM LICENSE_ANALYTICS_BY_FEATURE_PRODUCT_KEY_SUMMARY L WHERE L."PRODUCT_ID" = INPUT_PRODUCT_ID AND L."FEATURE_ID" = INPUT_FEATURE_ID; END;$$;


ALTER FUNCTION public.license_analytics_by_feature_get_product_key_summary(input_product_id integer, input_feature_id integer) OWNER TO postgres;

--
-- Name: license_analytics_by_host_get_feature_summary(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.license_analytics_by_host_get_feature_summary(input_product_key character varying, input_host_name character varying, input_host_ip character varying) RETURNS TABLE("ID" bigint, "FEATURE_NAME" character varying, "ACTIVE_UNTIL" timestamp without time zone, "HOST_NAME" character varying, "HOST_IP_ADDRESS" character varying, "PRODUCT_KEY" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN 
    RETURN QUERY 
    SELECT
        V."ID",
        V."FEATURE_NAME", 
        V."ACTIVE_UNTIL", 
        V."HOST_NAME", 
        V."HOST_IP_ADDRESS", 
        V."PRODUCT_KEY" 
    FROM LICENSE_ANALYTICS_BY_HOST_FEATURE_SUMMARY V 
    WHERE 
        V."PRODUCT_KEY" = INPUT_PRODUCT_KEY
        AND (
            V."HOST_NAME" IS NULL
            OR LOWER(V."HOST_NAME") = LOWER(INPUT_HOST_NAME)
        )
        AND (
            LOWER(V."HOST_IP_ADDRESS") = LOWER(INPUT_HOST_IP)
        );
END;
$$;


ALTER FUNCTION public.license_analytics_by_host_get_feature_summary(input_product_key character varying, input_host_name character varying, input_host_ip character varying) OWNER TO postgres;

--
-- Name: license_analytics_by_host_get_product_key_summary(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.license_analytics_by_host_get_product_key_summary(input_host_name character varying DEFAULT NULL::character varying, input_host_ip character varying DEFAULT NULL::character varying) RETURNS TABLE("PRODUCT_KEY" character varying, "PRODUCT_NAME" character varying, "HOST_IP_ADDRESS" character varying, "HOST_NAME" character varying, "LICENSED_TO" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN 
    RETURN QUERY 
    SELECT 
        L."PRODUCT_KEY", 
        L."PRODUCT_NAME",
        L."HOST_IP_ADDRESS",
        L."HOST_NAME",
        L."LICENSED_TO"
    FROM LICENSE_ANALYTICS_BY_HOST_PRODUCT_KEY_SUMMARY L 
    WHERE 
        (
            L."HOST_NAME" IS NULL
            OR LOWER(L."HOST_NAME") = LOWER(INPUT_HOST_NAME)
        )
      AND 
        (
            LOWER(L."HOST_IP_ADDRESS") = LOWER(INPUT_HOST_IP)
        );
END;
$$;


ALTER FUNCTION public.license_analytics_by_host_get_product_key_summary(input_host_name character varying, input_host_ip character varying) OWNER TO postgres;

--
-- Name: set_hardware_id(text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.set_hardware_id(IN p text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM set_config('rpm.hardware_id', p, false);
END;
$$;


ALTER PROCEDURE public.set_hardware_id(IN p text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ACTIVATION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ACTIVATION" (
    "ID" bigint NOT NULL,
    "HOSTNAME" character varying(255),
    "LAST_USED" timestamp without time zone,
    "CHECKED_OUT" boolean,
    "ACTIVE_UNTIL" timestamp without time zone,
    "ACTIVATED_USING_GRACE_PERIOD" boolean,
    "TIMEOUT" bigint,
    "ACTIVE_UNTIL_ACTIVATION_SERVER" timestamp without time zone,
    "HARDWARE_ID" character varying(255),
    "IP_ADDRESS" character varying(255),
    "LICENSE_KEY" character varying(255),
    "PRODUCT_KEY" bigint,
    "LICENSE" bigint,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ACTIVATION" OWNER TO postgres;

--
-- Name: ACTIVATION_HISTORY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ACTIVATION_HISTORY" (
    "ID" bigint NOT NULL,
    "HOSTNAME" character varying(255),
    "IP_ADDRESS" character varying(255),
    "LICENSE_KEY" character varying(255),
    "ACTIVATED_DATE" timestamp without time zone,
    "RELEASED_DATE" timestamp without time zone,
    "LICENSE" bigint,
    "PRODUCT_KEY" bigint
);


ALTER TABLE public."ACTIVATION_HISTORY" OWNER TO postgres;

--
-- Name: ACTIVATION_HISTORY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ACTIVATION_HISTORY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ACTIVATION_HISTORY_ID_seq" OWNER TO postgres;

--
-- Name: ACTIVATION_HISTORY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ACTIVATION_HISTORY_ID_seq" OWNED BY public."ACTIVATION_HISTORY"."ID";


--
-- Name: ACTIVATION_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ACTIVATION_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ACTIVATION_ID_seq" OWNER TO postgres;

--
-- Name: ACTIVATION_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ACTIVATION_ID_seq" OWNED BY public."ACTIVATION"."ID";


--
-- Name: ACTIVATION_SERVER_DATA; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ACTIVATION_SERVER_DATA" (
    "ID" bigint NOT NULL,
    "LAST_ONLINE" timestamp without time zone
);


ALTER TABLE public."ACTIVATION_SERVER_DATA" OWNER TO postgres;

--
-- Name: ACTIVATION_SERVER_DATA_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ACTIVATION_SERVER_DATA_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ACTIVATION_SERVER_DATA_ID_seq" OWNER TO postgres;

--
-- Name: ACTIVATION_SERVER_DATA_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ACTIVATION_SERVER_DATA_ID_seq" OWNED BY public."ACTIVATION_SERVER_DATA"."ID";


--
-- Name: ADVANCED_SEARCH; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ADVANCED_SEARCH" (
    "ID" bigint NOT NULL,
    "ALL_USERS" boolean,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "QUERY" character varying(1000),
    "VIEW" character varying(255),
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ADVANCED_SEARCH" OWNER TO postgres;

--
-- Name: ADVANCED_SEARCH_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ADVANCED_SEARCH_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ADVANCED_SEARCH_ID_seq" OWNER TO postgres;

--
-- Name: ADVANCED_SEARCH_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ADVANCED_SEARCH_ID_seq" OWNED BY public."ADVANCED_SEARCH"."ID";


--
-- Name: APP; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."APP" (
    "ID" bigint NOT NULL,
    "APP_ID" character varying(190),
    "COMPATIBILITY" character varying(255),
    "DESCRIPTION" character varying(255),
    "ICON" character varying(255),
    "NAME" character varying(190),
    "STATUS" character varying(190),
    "VENDOR" character varying(190),
    "VERSION" character varying(190),
    "WEBSITE" character varying(255)
);


ALTER TABLE public."APP" OWNER TO postgres;

--
-- Name: APP_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."APP_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."APP_ID_seq" OWNER TO postgres;

--
-- Name: APP_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."APP_ID_seq" OWNED BY public."APP"."ID";


--
-- Name: ATTRIBUTE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ATTRIBUTE" (
    "ID" bigint NOT NULL,
    "ACTIVE" boolean,
    "CHOICE_ORDER" character varying(255),
    "CONFIG" text,
    "CREATED" timestamp without time zone,
    "DEFAULT_VALUE" character varying(500),
    "DESCRIPTION" character varying(255),
    "EMPTY_CELL_COLOR" character varying(255),
    "EXCLUDE_INACTIVE" boolean,
    "FREE_ADD" boolean,
    "INCLUDED_ROLES" character varying(255),
    "KEY_NAME" character varying(255),
    "MAPPABLE" boolean,
    "MAXIMUM" character varying(255),
    "MINIMUM" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "POPULATED_CELL_BACK_COLOR" character varying(255),
    "POPULATED_CELL_FORE_COLOR" character varying(255),
    "STATIC_ATTRIBUTE" boolean,
    "TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "TYPE_ID" character varying(255) NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "CHOICE_LIST" bigint,
    "CREATED_BY" bigint,
    "ENTITY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ATTRIBUTE" OWNER TO postgres;

--
-- Name: ATTRIBUTE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ATTRIBUTE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ATTRIBUTE_ID_seq" OWNER TO postgres;

--
-- Name: ATTRIBUTE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ATTRIBUTE_ID_seq" OWNED BY public."ATTRIBUTE"."ID";


--
-- Name: ATTRIBUTE_PARAMETER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ATTRIBUTE_PARAMETER" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CUSTOM" boolean,
    "FORMAT" character varying(255),
    "MODIFIED" timestamp without time zone,
    "VERSION_ID" integer NOT NULL,
    "ATTRIBUTE" bigint,
    "ATTRIBUTE_PARAMETER_SET" bigint,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ATTRIBUTE_PARAMETER" OWNER TO postgres;

--
-- Name: ATTRIBUTE_PARAMETER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ATTRIBUTE_PARAMETER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ATTRIBUTE_PARAMETER_ID_seq" OWNER TO postgres;

--
-- Name: ATTRIBUTE_PARAMETER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ATTRIBUTE_PARAMETER_ID_seq" OWNED BY public."ATTRIBUTE_PARAMETER"."ID";


--
-- Name: ATTRIBUTE_PARAMETER_SET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ATTRIBUTE_PARAMETER_SET" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CUSTOM" boolean,
    "DESCRIPTION" character varying(255),
    "KEY_NAME" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "ROOT_DIRECTORY_TYPE_EXTENSION_ID" character varying(255),
    "ROOT_DIRECTORY_TYPE_ID" character varying(255),
    "SOURCE_ENTITY_DEFAULT" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "INHERIT_FROM" bigint,
    "MODIFIED_BY" bigint,
    "SOURCE_ENTITY" bigint,
    "VIRTUAL_DIRECTORY" bigint
);


ALTER TABLE public."ATTRIBUTE_PARAMETER_SET" OWNER TO postgres;

--
-- Name: ATTRIBUTE_PARAMETER_SET_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ATTRIBUTE_PARAMETER_SET_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ATTRIBUTE_PARAMETER_SET_ID_seq" OWNER TO postgres;

--
-- Name: ATTRIBUTE_PARAMETER_SET_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ATTRIBUTE_PARAMETER_SET_ID_seq" OWNED BY public."ATTRIBUTE_PARAMETER_SET"."ID";


--
-- Name: BUNDLE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."BUNDLE" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255),
    "VERSION" character varying(255)
);


ALTER TABLE public."BUNDLE" OWNER TO postgres;

--
-- Name: BUNDLE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."BUNDLE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."BUNDLE_ID_seq" OWNER TO postgres;

--
-- Name: BUNDLE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."BUNDLE_ID_seq" OWNED BY public."BUNDLE"."ID";


--
-- Name: C3P0; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."C3P0" (
    a character(1)
);


ALTER TABLE public."C3P0" OWNER TO postgres;

--
-- Name: CHOICE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CHOICE" (
    "ID" bigint NOT NULL,
    "ACTIVE" boolean,
    "BACKGROUND_COLOR" character varying(255),
    "CREATED" timestamp without time zone,
    "FOREGROUND_COLOR" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "VALUE" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CHOICE_LIST" bigint,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."CHOICE" OWNER TO postgres;

--
-- Name: CHOICE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CHOICE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CHOICE_ID_seq" OWNER TO postgres;

--
-- Name: CHOICE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CHOICE_ID_seq" OWNED BY public."CHOICE"."ID";


--
-- Name: CHOICE_LIST; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CHOICE_LIST" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "DESCRIPTION" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "TYPE_ID" character varying(255) NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."CHOICE_LIST" OWNER TO postgres;

--
-- Name: CHOICE_LIST_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CHOICE_LIST_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CHOICE_LIST_ID_seq" OWNER TO postgres;

--
-- Name: CHOICE_LIST_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CHOICE_LIST_ID_seq" OWNED BY public."CHOICE_LIST"."ID";


--
-- Name: CLOUD_TARGET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CLOUD_TARGET" (
    "ID" bigint NOT NULL,
    "INSTANCE_ID" character varying(255) NOT NULL,
    "USE_PUBLIC_IP" boolean DEFAULT false NOT NULL,
    "INSTANCE_STATE" character varying(255),
    "CLOUD_PROVIDER_TYPE_ID" character varying(255) NOT NULL,
    "CLOUD_PROVIDER_TYPE_EXTENSION_ID" character varying(255) NOT NULL
);


ALTER TABLE public."CLOUD_TARGET" OWNER TO postgres;

--
-- Name: COMPONENT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."COMPONENT" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "RELEASE" bigint,
    "NAME" character varying(255),
    "INSTALLER_NAME" character varying(255),
    "DEFAULT_PATH" character varying(255),
    "INSTALLER_ARGS" character varying(255),
    "MD5HASH" character varying(255),
    "TAG" character varying(255),
    "CONFIGURATION" character varying(255),
    "PRODUCT_INSTALLER_ID" character varying(255),
    "PRODUCT_PASSWORD" character varying(255),
    "STARTUP_PROCESS" character varying(255),
    "SNAPSHOTS_ENABLED" boolean,
    "VALID_TARGET_PLATFORMS" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."COMPONENT" OWNER TO postgres;

--
-- Name: COMPONENT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."COMPONENT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."COMPONENT_ID_seq" OWNER TO postgres;

--
-- Name: COMPONENT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."COMPONENT_ID_seq" OWNED BY public."COMPONENT"."ID";


--
-- Name: COMPONENT_PROCESS; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."COMPONENT_PROCESS" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255),
    "TYPE" character varying(255),
    "SERVICE_NAME" character varying(255),
    "IS_SERVICE" boolean DEFAULT false,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint,
    "COMPONENT" bigint,
    "INDEX" integer
);


ALTER TABLE public."COMPONENT_PROCESS" OWNER TO postgres;

--
-- Name: COMPONENT_PROCESS_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."COMPONENT_PROCESS_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."COMPONENT_PROCESS_ID_seq" OWNER TO postgres;

--
-- Name: COMPONENT_PROCESS_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."COMPONENT_PROCESS_ID_seq" OWNED BY public."COMPONENT_PROCESS"."ID";


--
-- Name: CONFIGURATION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CONFIGURATION" (
    "ID" bigint NOT NULL,
    "BUNDLE" character varying(190),
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190),
    "VALUE" text,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."CONFIGURATION" OWNER TO postgres;

--
-- Name: CONFIGURATION_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CONFIGURATION_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CONFIGURATION_ID_seq" OWNER TO postgres;

--
-- Name: CONFIGURATION_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CONFIGURATION_ID_seq" OWNED BY public."CONFIGURATION"."ID";


--
-- Name: CONFIGURATION_SNAPSHOT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CONFIGURATION_SNAPSHOT" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "DESCRIPTION" character varying(255) NOT NULL,
    "PARENT" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint,
    "TYPE" character varying(255)
);


ALTER TABLE public."CONFIGURATION_SNAPSHOT" OWNER TO postgres;

--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CONFIGURATION_SNAPSHOT_HISTORY" (
    "ID" bigint NOT NULL,
    "TARGET_ID" bigint,
    "SOURCE_TARGET_ID" bigint,
    "CONFIGURATION_SNAPSHOT_ID" bigint,
    "COMPONENT_ID" bigint,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint
);


ALTER TABLE public."CONFIGURATION_SNAPSHOT_HISTORY" OWNER TO postgres;

--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CONFIGURATION_SNAPSHOT_HISTORY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CONFIGURATION_SNAPSHOT_HISTORY_ID_seq" OWNER TO postgres;

--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CONFIGURATION_SNAPSHOT_HISTORY_ID_seq" OWNED BY public."CONFIGURATION_SNAPSHOT_HISTORY"."ID";


--
-- Name: CONFIGURATION_SNAPSHOT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CONFIGURATION_SNAPSHOT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CONFIGURATION_SNAPSHOT_ID_seq" OWNER TO postgres;

--
-- Name: CONFIGURATION_SNAPSHOT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CONFIGURATION_SNAPSHOT_ID_seq" OWNED BY public."CONFIGURATION_SNAPSHOT"."ID";


--
-- Name: CUSTOM_PANEL_FILE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CUSTOM_PANEL_FILE" (
    "ID" bigint NOT NULL,
    "CUSTOM_PANEL_NAMESPACE_ID" character varying(36),
    "FILE_VERSION" integer NOT NULL,
    "UPLOADED_BY_ID" bigint,
    "UPLOADED_BY_DISPLAY_NAME" character varying(255),
    "PUBLISHED_BY_ID" bigint,
    "PUBLISHED_BY_DISPLAY_NAME" character varying(255),
    "UPLOAD_TIME" timestamp without time zone NOT NULL,
    "PUBLISHED" boolean,
    "CUSTOM_PANEL_VERSION" character varying(255),
    "NOTES" character varying(255)
);


ALTER TABLE public."CUSTOM_PANEL_FILE" OWNER TO postgres;

--
-- Name: CUSTOM_PANEL_FILE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."CUSTOM_PANEL_FILE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."CUSTOM_PANEL_FILE_ID_seq" OWNER TO postgres;

--
-- Name: CUSTOM_PANEL_FILE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."CUSTOM_PANEL_FILE_ID_seq" OWNED BY public."CUSTOM_PANEL_FILE"."ID";


--
-- Name: CUSTOM_PANEL_NAMESPACE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CUSTOM_PANEL_NAMESPACE" (
    "ID" character varying(36) NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "PARENT_ID" bigint NOT NULL,
    "PUBLIC_ACCESS" boolean DEFAULT false NOT NULL
);


ALTER TABLE public."CUSTOM_PANEL_NAMESPACE" OWNER TO postgres;

--
-- Name: DEPLOYMENT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DEPLOYMENT" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "LOCK" boolean,
    "RELEASE" bigint,
    "PARENT" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."DEPLOYMENT" OWNER TO postgres;

--
-- Name: DEPLOYMENT_COMPONENT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DEPLOYMENT_COMPONENT" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "TARGET" bigint NOT NULL,
    "COMPONENT" bigint NOT NULL,
    "STATE" character varying(255),
    "STATE_REASON" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint,
    "DEPLOYMENT" bigint,
    "INDEX" integer
);


ALTER TABLE public."DEPLOYMENT_COMPONENT" OWNER TO postgres;

--
-- Name: DEPLOYMENT_COMPONENT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."DEPLOYMENT_COMPONENT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DEPLOYMENT_COMPONENT_ID_seq" OWNER TO postgres;

--
-- Name: DEPLOYMENT_COMPONENT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."DEPLOYMENT_COMPONENT_ID_seq" OWNED BY public."DEPLOYMENT_COMPONENT"."ID";


--
-- Name: DEPLOYMENT_CONFIGURATION_SNAPSHOT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DEPLOYMENT_CONFIGURATION_SNAPSHOT" (
    "ID" bigint NOT NULL,
    "DEPLOYMENT_ID" bigint
);


ALTER TABLE public."DEPLOYMENT_CONFIGURATION_SNAPSHOT" OWNER TO postgres;

--
-- Name: DEPLOYMENT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."DEPLOYMENT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DEPLOYMENT_ID_seq" OWNER TO postgres;

--
-- Name: DEPLOYMENT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."DEPLOYMENT_ID_seq" OWNED BY public."DEPLOYMENT"."ID";


--
-- Name: DISK_USAGE_MONITOR; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DISK_USAGE_MONITOR" (
    "BYTE_TYPE" character varying(255),
    "DRIVE_LETTER" character varying(255),
    "THRESHOLD" bigint,
    "ID" bigint NOT NULL
);


ALTER TABLE public."DISK_USAGE_MONITOR" OWNER TO postgres;

--
-- Name: DISPLAY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DISPLAY" (
    "ID" bigint NOT NULL,
    "CONFIG" text,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "TYPE_ID" character varying(255) NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MANAGER" bigint NOT NULL,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."DISPLAY" OWNER TO postgres;

--
-- Name: DISPLAY_ATTRIBUTE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DISPLAY_ATTRIBUTE" (
    "DISPLAY" bigint NOT NULL,
    "ATTRIBUTE" bigint NOT NULL
);


ALTER TABLE public."DISPLAY_ATTRIBUTE" OWNER TO postgres;

--
-- Name: DISPLAY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."DISPLAY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."DISPLAY_ID_seq" OWNER TO postgres;

--
-- Name: DISPLAY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."DISPLAY_ID_seq" OWNED BY public."DISPLAY"."ID";


--
-- Name: ENTITY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "GLOBALLY_SEARCHABLE" boolean,
    "ICON" character varying(255),
    "INTERNAL" boolean,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "REPORTABLE" boolean,
    "STATIC_ENTITY" boolean,
    "TABLE" character varying(255),
    "USER_CONFIGURABLE" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "TITLE_ATTRIBUTE" bigint
);


ALTER TABLE public."ENTITY" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_CONNECTION" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "EDIT_FORM_DISPLAY_MODE" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255) NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "CREATE_FORM" bigint,
    "CREATED_BY" bigint,
    "EDIT_FORM" bigint,
    "FROM_ENTITY" bigint NOT NULL,
    "MODIFIED_BY" bigint,
    "TO_ENTITY" bigint NOT NULL
);


ALTER TABLE public."ENTITY_CONNECTION" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "CREATED_BY" bigint,
    "ENTITY_CONNECTION" bigint,
    "FROM_ENTITY_ATTRIBUTE" bigint NOT NULL,
    "MODIFIED_BY" bigint,
    "TO_ENTITY_ATTRIBUTE" bigint NOT NULL
);


ALTER TABLE public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq" OWNED BY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"."ID";


--
-- Name: ENTITY_CONNECTION_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_CONNECTION_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_CONNECTION_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_CONNECTION_ID_seq" OWNED BY public."ENTITY_CONNECTION"."ID";


--
-- Name: ENTITY_CONNECTION_INSTANCE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_CONNECTION_INSTANCE" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "FROM_INSTANCE" bigint NOT NULL,
    "MODIFIED" timestamp without time zone,
    "TO_INSTANCE" bigint NOT NULL,
    "CREATED_BY" bigint,
    "ENTITY_CONNECTION" bigint NOT NULL,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ENTITY_CONNECTION_INSTANCE" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_INSTANCE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_CONNECTION_INSTANCE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_CONNECTION_INSTANCE_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_CONNECTION_INSTANCE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_CONNECTION_INSTANCE_ID_seq" OWNED BY public."ENTITY_CONNECTION_INSTANCE"."ID";


--
-- Name: ENTITY_FORM; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_FORM" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "HIDDEN" boolean,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "REQUIRE_FORM" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "ENTITY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ENTITY_FORM" OWNER TO postgres;

--
-- Name: ENTITY_FORM_ATTRIBUTE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_FORM_ATTRIBUTE" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "LABEL" text,
    "MODIFIED" timestamp without time zone,
    "READ_ONLY" boolean,
    "REQUIRED" boolean,
    "VERSION_ID" integer NOT NULL,
    "ATTRIBUTE" bigint,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "ENTITY_FORM" bigint,
    "ORDER" integer
);


ALTER TABLE public."ENTITY_FORM_ATTRIBUTE" OWNER TO postgres;

--
-- Name: ENTITY_FORM_ATTRIBUTE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_FORM_ATTRIBUTE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_FORM_ATTRIBUTE_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_FORM_ATTRIBUTE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_FORM_ATTRIBUTE_ID_seq" OWNED BY public."ENTITY_FORM_ATTRIBUTE"."ID";


--
-- Name: ENTITY_FORM_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_FORM_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_FORM_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_FORM_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_FORM_ID_seq" OWNED BY public."ENTITY_FORM"."ID";


--
-- Name: ENTITY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_ID_seq" OWNED BY public."ENTITY"."ID";


--
-- Name: ENTITY_INSTANCE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_INSTANCE" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "ORDER" bigint,
    "USER_ATTRIBUTES" text,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "ENTITY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ENTITY_INSTANCE" OWNER TO postgres;

--
-- Name: ENTITY_INSTANCE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_INSTANCE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_INSTANCE_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_INSTANCE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_INSTANCE_ID_seq" OWNED BY public."ENTITY_INSTANCE"."ID";


--
-- Name: ENTITY_MANAGER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ENTITY_MANAGER" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "EDIT_FORM_DISPLAY_MODE" character varying(255),
    "MODIFIED" timestamp without time zone,
    "VERSION_ID" integer NOT NULL,
    "CREATE_FORM" bigint,
    "CREATED_BY" bigint,
    "EDIT_FORM" bigint,
    "ENTITY" bigint NOT NULL,
    "MANAGER" bigint NOT NULL,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ENTITY_MANAGER" OWNER TO postgres;

--
-- Name: ENTITY_MANAGER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ENTITY_MANAGER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ENTITY_MANAGER_ID_seq" OWNER TO postgres;

--
-- Name: ENTITY_MANAGER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ENTITY_MANAGER_ID_seq" OWNED BY public."ENTITY_MANAGER"."ID";


--
-- Name: FEATURE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FEATURE" (
    "ID" bigint NOT NULL,
    "FULL_FEATURE_ID" character varying(255),
    "PRODUCT_FEATURE_ID" character varying(255),
    "NAME" character varying(255),
    "DESCRIPTION" character varying(255),
    "KEY" character varying(255),
    "MAINTENANCE" boolean,
    "PRODUCT" bigint,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."FEATURE" OWNER TO postgres;

--
-- Name: FEATURE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."FEATURE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."FEATURE_ID_seq" OWNER TO postgres;

--
-- Name: FEATURE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."FEATURE_ID_seq" OWNED BY public."FEATURE"."ID";


--
-- Name: FEDERATED_SEARCH; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FEDERATED_SEARCH" (
    "ID" bigint NOT NULL,
    "BY_USER" character varying(2048),
    "CREATED" timestamp without time zone,
    "CREATED_END" timestamp without time zone,
    "CREATED_START" timestamp without time zone,
    "DESCRIPTOR_ID" character varying(190),
    "LOCATIONS" character varying(4000),
    "MISCELLANEOUS_END" timestamp without time zone,
    "MISCELLANEOUS_START" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_END" timestamp without time zone,
    "MODIFIED_START" timestamp without time zone,
    "OPTIONS" character varying(255),
    "QUERY" character varying(1024),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."FEDERATED_SEARCH" OWNER TO postgres;

--
-- Name: FEDERATED_SEARCH_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."FEDERATED_SEARCH_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."FEDERATED_SEARCH_ID_seq" OWNER TO postgres;

--
-- Name: FEDERATED_SEARCH_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."FEDERATED_SEARCH_ID_seq" OWNED BY public."FEDERATED_SEARCH"."ID";


--
-- Name: FILE_SYSTEM; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FILE_SYSTEM" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CREDENTIALS" text,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190),
    "NAMESPACE" character varying(190),
    "PROVIDER" character varying(190),
    "ROOT" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."FILE_SYSTEM" OWNER TO postgres;

--
-- Name: FILE_SYSTEM_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."FILE_SYSTEM_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."FILE_SYSTEM_ID_seq" OWNER TO postgres;

--
-- Name: FILE_SYSTEM_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."FILE_SYSTEM_ID_seq" OWNED BY public."FILE_SYSTEM"."ID";


--
-- Name: GATEWAY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."GATEWAY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "HOST" character varying(190),
    "MODIFIED" timestamp without time zone,
    "SECRET" character varying(190),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."GATEWAY" OWNER TO postgres;

--
-- Name: GATEWAY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."GATEWAY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."GATEWAY_ID_seq" OWNER TO postgres;

--
-- Name: GATEWAY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."GATEWAY_ID_seq" OWNED BY public."GATEWAY"."ID";


--
-- Name: HOST; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."HOST" (
    "ID" bigint NOT NULL,
    "HARDWARE_ID" character varying(255),
    "IP" character varying(255),
    "TYPE" character varying(255),
    "USER_NAME" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."HOST" OWNER TO postgres;

--
-- Name: HOST_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."HOST_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."HOST_ID_seq" OWNER TO postgres;

--
-- Name: HOST_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."HOST_ID_seq" OWNED BY public."HOST"."ID";


--
-- Name: HOTKEY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."HOTKEY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "EXTENSION" character varying(190),
    "HOTKEY" character varying(190),
    "MODIFIED" timestamp without time zone,
    "OBJECT" character varying(255),
    "ORDER" integer,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."HOTKEY" OWNER TO postgres;

--
-- Name: HOTKEY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."HOTKEY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."HOTKEY_ID_seq" OWNER TO postgres;

--
-- Name: HOTKEY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."HOTKEY_ID_seq" OWNED BY public."HOTKEY"."ID";


--
-- Name: INTERNET_CONN_MONITOR; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."INTERNET_CONN_MONITOR" (
    "TIME_UNIT" bytea,
    "URL" character varying(255),
    "ID" bigint NOT NULL
);


ALTER TABLE public."INTERNET_CONN_MONITOR" OWNER TO postgres;

--
-- Name: JOB; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."JOB" (
    "ID" bigint NOT NULL,
    "ALIAS" character varying(190),
    "BUNDLE" character varying(190),
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."JOB" OWNER TO postgres;

--
-- Name: JOB_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."JOB_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."JOB_ID_seq" OWNER TO postgres;

--
-- Name: JOB_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."JOB_ID_seq" OWNED BY public."JOB"."ID";


--
-- Name: JOB_NODE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."JOB_NODE" (
    "JOB" bigint NOT NULL,
    "NODE" bigint NOT NULL,
    "INDEX" integer NOT NULL
);


ALTER TABLE public."JOB_NODE" OWNER TO postgres;

--
-- Name: LICENSE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LICENSE" (
    "ID" bigint NOT NULL,
    "KEY" character varying(255),
    "REQUEST_CODE" character varying(255),
    "LICENSED_TO" character varying(255),
    "PURCHASED" boolean,
    "ACTIVATION_LIMIT" integer,
    "ACTIVATED_OFFLINE" boolean DEFAULT false NOT NULL,
    "NUMBER" integer,
    "FEATURE" bigint,
    "PRODUCT_KEY" bigint,
    "MAINTENANCE_EXPIRY" date,
    "PURCHASE_DATE" timestamp without time zone,
    "EXPIRY_DATE" timestamp without time zone,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."LICENSE" OWNER TO postgres;

--
-- Name: LICENSE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."LICENSE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."LICENSE_ID_seq" OWNER TO postgres;

--
-- Name: LICENSE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."LICENSE_ID_seq" OWNED BY public."LICENSE"."ID";


--
-- Name: LICENSE_KEY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LICENSE_KEY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "FEATURE_ID" character varying(190),
    "KEY" character varying(190),
    "LICENSED_TO" character varying(255),
    "MODIFIED" timestamp without time zone,
    "REQUEST_CODE" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "NODE" bigint
);


ALTER TABLE public."LICENSE_KEY" OWNER TO postgres;

--
-- Name: LICENSE_KEY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."LICENSE_KEY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."LICENSE_KEY_ID_seq" OWNER TO postgres;

--
-- Name: LICENSE_KEY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."LICENSE_KEY_ID_seq" OWNED BY public."LICENSE_KEY"."ID";


--
-- Name: MAIL_RECIPIENT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MAIL_RECIPIENT" (
    "ID" bigint NOT NULL,
    "EMAIL" character varying(255) NOT NULL,
    "FULL_NAME" character varying(255) NOT NULL,
    "SUBSCRIPTION_NOTIFICATIONS_ENABLED" boolean DEFAULT false NOT NULL,
    "MAINTENANCE_NOTIFICATIONS_ENABLED" boolean DEFAULT false NOT NULL,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."MAIL_RECIPIENT" OWNER TO postgres;

--
-- Name: MAIL_RECIPIENT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."MAIL_RECIPIENT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."MAIL_RECIPIENT_ID_seq" OWNER TO postgres;

--
-- Name: MAIL_RECIPIENT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."MAIL_RECIPIENT_ID_seq" OWNED BY public."MAIL_RECIPIENT"."ID";


--
-- Name: MAIL_SERVER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MAIL_SERVER" (
    "ID" bigint NOT NULL,
    "OUTGOING_HOST" character varying(255),
    "OUTGOING_PORT" integer,
    "OUTGOING_ENCRYPTION" character varying(255),
    "OUTGOING_AUTHENTICATED" boolean,
    "OUTGOING_USERNAME" character varying(255),
    "OUTGOING_PASSWORD" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."MAIL_SERVER" OWNER TO postgres;

--
-- Name: MAIL_SERVER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."MAIL_SERVER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."MAIL_SERVER_ID_seq" OWNER TO postgres;

--
-- Name: MAIL_SERVER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."MAIL_SERVER_ID_seq" OWNED BY public."MAIL_SERVER"."ID";


--
-- Name: MANAGER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MANAGER" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "ICON" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255) NOT NULL,
    "SHOW_IN_WORKBENCH" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."MANAGER" OWNER TO postgres;

--
-- Name: MANAGER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."MANAGER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."MANAGER_ID_seq" OWNER TO postgres;

--
-- Name: MANAGER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."MANAGER_ID_seq" OWNED BY public."MANAGER"."ID";


--
-- Name: MONITOR; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MONITOR" (
    "ID" bigint NOT NULL,
    "ALIAS" character varying(255),
    "BUNDLE" character varying(255),
    "CREATED" timestamp without time zone,
    "ENABLED" boolean,
    "INTERVAL" bigint,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190),
    "TIME_TYPE" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."MONITOR" OWNER TO postgres;

--
-- Name: MONITOR_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."MONITOR_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."MONITOR_ID_seq" OWNER TO postgres;

--
-- Name: MONITOR_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."MONITOR_ID_seq" OWNED BY public."MONITOR"."ID";


--
-- Name: NODE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."NODE" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "ENABLED" boolean,
    "HOST" character varying(190),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190),
    "ONLINE" boolean,
    "UNIQUE_ID" bigint,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."NODE" OWNER TO postgres;

--
-- Name: NODE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."NODE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."NODE_ID_seq" OWNER TO postgres;

--
-- Name: NODE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."NODE_ID_seq" OWNED BY public."NODE"."ID";


--
-- Name: NODE_STATUS; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."NODE_STATUS" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MESSAGE" character varying(255),
    "MODIFIED" timestamp without time zone,
    "ONLINE" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "DESTINATION" bigint,
    "MODIFIED_BY" bigint,
    "SOURCE" bigint
);


ALTER TABLE public."NODE_STATUS" OWNER TO postgres;

--
-- Name: NODE_STATUS_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."NODE_STATUS_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."NODE_STATUS_ID_seq" OWNER TO postgres;

--
-- Name: NODE_STATUS_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."NODE_STATUS_ID_seq" OWNED BY public."NODE_STATUS"."ID";


--
-- Name: OGP_ATTRIBUTE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OGP_ATTRIBUTE" (
    "OGP_KEY" character varying(255),
    "OGP_READ_ONLY" boolean,
    "OGP_TYPE" character varying(255),
    "OGP_WIDGET" character varying(255),
    "ID" bigint NOT NULL
);


ALTER TABLE public."OGP_ATTRIBUTE" OWNER TO postgres;

--
-- Name: OGP_CHOICE_LIST; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OGP_CHOICE_LIST" (
    "OGP_TYPE" character varying(255),
    "ID" bigint NOT NULL
);


ALTER TABLE public."OGP_CHOICE_LIST" OWNER TO postgres;

--
-- Name: OGP_ENTITY_FORM; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OGP_ENTITY_FORM" (
    "MENU_ID" bigint,
    "OGP_KEY" character varying(255),
    "ID" bigint NOT NULL,
    "OGP_MENU_GROUP" bigint
);


ALTER TABLE public."OGP_ENTITY_FORM" OWNER TO postgres;

--
-- Name: OGP_FRAME; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OGP_FRAME" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "HOSTNAME" character varying(255) NOT NULL,
    "PORT" integer NOT NULL,
    "PROTOCOL" character varying(255) NOT NULL,
    "USE_SSL" boolean DEFAULT false,
    "CONNECTION_SETTINGS" text,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone
);


ALTER TABLE public."OGP_FRAME" OWNER TO postgres;

--
-- Name: OGP_FRAME_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."OGP_FRAME_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNER TO postgres;

--
-- Name: OGP_FRAME_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNED BY public."OGP_FRAME"."ID";


--
-- Name: OGP_MENU_GROUP; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."OGP_MENU_GROUP" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "OGP_KEY" character varying(255),
    "OGP_MENU_ID" bigint,
    "OGP_NAME" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."OGP_MENU_GROUP" OWNER TO postgres;

--
-- Name: OGP_MENU_GROUP_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."OGP_MENU_GROUP_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."OGP_MENU_GROUP_ID_seq" OWNER TO postgres;

--
-- Name: OGP_MENU_GROUP_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."OGP_MENU_GROUP_ID_seq" OWNED BY public."OGP_MENU_GROUP"."ID";


--
-- Name: PARAMETER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PARAMETER" (
    "ID" bigint NOT NULL,
    "CATEGORY" character varying(255),
    "CREATED" timestamp without time zone,
    "CUSTOM" boolean,
    "DELIMETER" character varying(255),
    "FAMILY_GROUP_ZERO" character varying(255),
    "KEY" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAMESPACE_URI" character varying(255),
    "ORDINAL" bigint,
    "PROVIDER" character varying(255),
    "VALUE" text,
    "VERSION_ID" integer NOT NULL,
    "ATTRIBUTE_PARAMETER" bigint,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "PARAMETER_SET" bigint
);


ALTER TABLE public."PARAMETER" OWNER TO postgres;

--
-- Name: PARAMETER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PARAMETER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PARAMETER_ID_seq" OWNER TO postgres;

--
-- Name: PARAMETER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PARAMETER_ID_seq" OWNED BY public."PARAMETER"."ID";


--
-- Name: PARAMETER_SET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PARAMETER_SET" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CUSTOM" boolean,
    "DESCRIPTION" character varying(255),
    "KEY_NAME" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."PARAMETER_SET" OWNER TO postgres;

--
-- Name: PARAMETER_SET_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PARAMETER_SET_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PARAMETER_SET_ID_seq" OWNER TO postgres;

--
-- Name: PARAMETER_SET_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PARAMETER_SET_ID_seq" OWNED BY public."PARAMETER_SET"."ID";


--
-- Name: PERMISSION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PERMISSION" (
    "ID" bigint NOT NULL,
    "AUTHORIZED" boolean NOT NULL,
    "BUNDLE" character varying(190),
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "OBJECT" bigint,
    "PERMISSION" character varying(190),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "ROLE" bigint,
    "SCOPE" bigint
);


ALTER TABLE public."PERMISSION" OWNER TO postgres;

--
-- Name: PERMISSION_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PERMISSION_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PERMISSION_ID_seq" OWNER TO postgres;

--
-- Name: PERMISSION_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PERMISSION_ID_seq" OWNED BY public."PERMISSION"."ID";


--
-- Name: PERSPECTIVE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PERSPECTIVE" (
    "ID" bigint NOT NULL,
    "BINDINGS" text,
    "CREATED" timestamp without time zone,
    "MOBILE" boolean,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "SYSTEM_DEFAULT" boolean,
    "VERSION_ID" integer NOT NULL,
    "WORKBENCH" character varying(190),
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "USER" bigint
);


ALTER TABLE public."PERSPECTIVE" OWNER TO postgres;

--
-- Name: PERSPECTIVE_COLUMN; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PERSPECTIVE_COLUMN" (
    "ID" bigint NOT NULL,
    "COLUMN" character varying(255),
    "CREATED" timestamp without time zone,
    "GRID" character varying(255),
    "MODIFIED" timestamp without time zone,
    "ORDER" integer,
    "VERSION_ID" integer NOT NULL,
    "VIEW" character varying(190),
    "WIDTH" integer,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "PERSPECTIVE" bigint
);


ALTER TABLE public."PERSPECTIVE_COLUMN" OWNER TO postgres;

--
-- Name: PERSPECTIVE_COLUMN_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PERSPECTIVE_COLUMN_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PERSPECTIVE_COLUMN_ID_seq" OWNER TO postgres;

--
-- Name: PERSPECTIVE_COLUMN_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PERSPECTIVE_COLUMN_ID_seq" OWNED BY public."PERSPECTIVE_COLUMN"."ID";


--
-- Name: PERSPECTIVE_FIELD; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PERSPECTIVE_FIELD" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "FIELD" character varying(255),
    "MODIFIED" timestamp without time zone,
    "ORDER" integer,
    "VERSION_ID" integer NOT NULL,
    "VIEW" character varying(190),
    "WIDTH" integer,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "PERSPECTIVE" bigint
);


ALTER TABLE public."PERSPECTIVE_FIELD" OWNER TO postgres;

--
-- Name: PERSPECTIVE_FIELD_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PERSPECTIVE_FIELD_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PERSPECTIVE_FIELD_ID_seq" OWNER TO postgres;

--
-- Name: PERSPECTIVE_FIELD_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PERSPECTIVE_FIELD_ID_seq" OWNED BY public."PERSPECTIVE_FIELD"."ID";


--
-- Name: PERSPECTIVE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PERSPECTIVE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PERSPECTIVE_ID_seq" OWNER TO postgres;

--
-- Name: PERSPECTIVE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PERSPECTIVE_ID_seq" OWNED BY public."PERSPECTIVE"."ID";


--
-- Name: PREFERENCE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PREFERENCE" (
    "ID" bigint NOT NULL,
    "BUNDLE" character varying(190),
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190),
    "VALUE" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "USER" bigint
);


ALTER TABLE public."PREFERENCE" OWNER TO postgres;

--
-- Name: PREFERENCE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PREFERENCE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PREFERENCE_ID_seq" OWNER TO postgres;

--
-- Name: PREFERENCE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PREFERENCE_ID_seq" OWNED BY public."PREFERENCE"."ID";


--
-- Name: PRODUCT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PRODUCT" (
    "ID" bigint NOT NULL,
    "PRODUCT_ID" integer,
    "NAME" character varying(255),
    "ALIAS" character varying(255),
    "USE_FEATURE_LEVEL_MAINTENANCE" boolean,
    "LICENSING_MODE" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."PRODUCT" OWNER TO postgres;

--
-- Name: PRODUCT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PRODUCT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PRODUCT_ID_seq" OWNER TO postgres;

--
-- Name: PRODUCT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PRODUCT_ID_seq" OWNED BY public."PRODUCT"."ID";


--
-- Name: PRODUCT_KEY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PRODUCT_KEY" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "KEY" character varying(255),
    "LICENCED_TO" character varying(255),
    "MAINTENANCE_EXPIRY_DATE" date,
    "CUSTOMER_DEPARTMENT" character varying(255),
    "CUSTOMER_ID" character varying(255),
    "LICENSED_SOFTWARE_VERSION" character varying(255),
    "ACTIVATED" boolean,
    "RUNNING_SOFTWARE_VERSION" character varying(255),
    "OFFLINE_REQUEST_CODE" bytea,
    "NOTES" character varying(255),
    "ACTIVATION_REQ_FILE_DUE_DATE" timestamp without time zone,
    "DISABLED" boolean DEFAULT false NOT NULL,
    "DEACTIVATION_REQUESTED" boolean DEFAULT false NOT NULL,
    "CHECKED_OUT_HARDWARE_ID" character varying(255),
    "PRODUCT" bigint,
    "PARENT" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."PRODUCT_KEY" OWNER TO postgres;

--
-- Name: PRODUCT_KEY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."PRODUCT_KEY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."PRODUCT_KEY_ID_seq" OWNER TO postgres;

--
-- Name: PRODUCT_KEY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."PRODUCT_KEY_ID_seq" OWNED BY public."PRODUCT_KEY"."ID";


--
-- Name: PUBLIC_KEY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PUBLIC_KEY" (
    "NODE" bigint NOT NULL,
    "KEY" character varying(2048),
    "IS_AUTHORIZED" boolean DEFAULT true NOT NULL
);


ALTER TABLE public."PUBLIC_KEY" OWNER TO postgres;

--
-- Name: RELEASE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."RELEASE" (
    "ID" bigint NOT NULL,
    "PRODUCT" bigint,
    "STREAM" character varying(255),
    "VERSION" character varying(255),
    "KEY" character varying(255),
    "URL" character varying(255),
    "DEPLOYMENT_PACKAGE_URL" text,
    "SUMMARY" character varying(255),
    "RELEASE_DATE" timestamp without time zone,
    "MAINTENANCE_DATE" timestamp without time zone,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."RELEASE" OWNER TO postgres;

--
-- Name: RELEASE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."RELEASE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."RELEASE_ID_seq" OWNER TO postgres;

--
-- Name: RELEASE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."RELEASE_ID_seq" OWNED BY public."RELEASE"."ID";


--
-- Name: REMOTE_KEY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."REMOTE_KEY" (
    "ID" bigint NOT NULL,
    "KEY" character varying(1000000),
    "IV" character varying(255)
);


ALTER TABLE public."REMOTE_KEY" OWNER TO postgres;

--
-- Name: REMOTE_KEY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."REMOTE_KEY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."REMOTE_KEY_ID_seq" OWNER TO postgres;

--
-- Name: REMOTE_KEY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."REMOTE_KEY_ID_seq" OWNED BY public."REMOTE_KEY"."ID";


--
-- Name: REPORT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."REPORT" (
    "ID" bigint NOT NULL,
    "CONFIGURATION" text,
    "CREATED" timestamp without time zone,
    "DESCENDING" boolean,
    "DESCRIPTION" character varying(255),
    "FILTERS" text,
    "LIMIT" integer,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190) NOT NULL,
    "PURGE_DAY_LIMIT" integer,
    "TEMPLATE" boolean,
    "TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "TYPE_ID" character varying(255) NOT NULL,
    "CREATED_BY" bigint,
    "ENTITY" bigint NOT NULL,
    "MODIFIED_BY" bigint,
    "ORDER_BY" bigint
);


ALTER TABLE public."REPORT" OWNER TO postgres;

--
-- Name: REPORT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."REPORT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."REPORT_ID_seq" OWNER TO postgres;

--
-- Name: REPORT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."REPORT_ID_seq" OWNED BY public."REPORT"."ID";


--
-- Name: REPORT_RUN; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."REPORT_RUN" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "DATA" text,
    "END" timestamp without time zone,
    "MESSAGE" text,
    "MODIFIED" timestamp without time zone,
    "REPORT_VERSION" integer,
    "START" timestamp without time zone,
    "STATUS" character varying(16) NOT NULL,
    "TIME_ZONE" character varying(255),
    "ACTIVE_NODE" bigint,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "REPORT" bigint NOT NULL
);


ALTER TABLE public."REPORT_RUN" OWNER TO postgres;

--
-- Name: REPORT_RUN_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."REPORT_RUN_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."REPORT_RUN_ID_seq" OWNER TO postgres;

--
-- Name: REPORT_RUN_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."REPORT_RUN_ID_seq" OWNED BY public."REPORT_RUN"."ID";


--
-- Name: ROLE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ROLE" (
    "ID" bigint NOT NULL,
    "ACTIVE" boolean,
    "ADMINISTRATIVE" boolean,
    "CREATED" timestamp without time zone,
    "DOMAIN" character varying(190),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "REMOTELY_ASSIGNABLE" boolean,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."ROLE" OWNER TO postgres;

--
-- Name: ROLE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ROLE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ROLE_ID_seq" OWNER TO postgres;

--
-- Name: ROLE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ROLE_ID_seq" OWNED BY public."ROLE"."ID";


--
-- Name: ROSS_PLATFORM_TARGET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ROSS_PLATFORM_TARGET" (
    "ID" bigint NOT NULL,
    "ROSS_PLATFORM" character varying(255),
    "LOCK" boolean
);


ALTER TABLE public."ROSS_PLATFORM_TARGET" OWNER TO postgres;

--
-- Name: SDPE_AVAILABLE_MODES; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SDPE_AVAILABLE_MODES" (
    "ID" bigint NOT NULL,
    "TARGET_ID" bigint,
    "MODE" character varying(255) NOT NULL,
    "INDEX" integer
);


ALTER TABLE public."SDPE_AVAILABLE_MODES" OWNER TO postgres;

--
-- Name: SDPE_AVAILABLE_MODES_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."SDPE_AVAILABLE_MODES_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."SDPE_AVAILABLE_MODES_ID_seq" OWNER TO postgres;

--
-- Name: SDPE_AVAILABLE_MODES_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."SDPE_AVAILABLE_MODES_ID_seq" OWNED BY public."SDPE_AVAILABLE_MODES"."ID";


--
-- Name: SEARCH_INDEX; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SEARCH_INDEX" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255),
    "STATUS" character varying(190)
);


ALTER TABLE public."SEARCH_INDEX" OWNER TO postgres;

--
-- Name: SEARCH_INDEX_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."SEARCH_INDEX_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."SEARCH_INDEX_ID_seq" OWNER TO postgres;

--
-- Name: SEARCH_INDEX_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."SEARCH_INDEX_ID_seq" OWNED BY public."SEARCH_INDEX"."ID";


--
-- Name: SYNCTHING_DEVICE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SYNCTHING_DEVICE" (
    "NODE_ID" bigint NOT NULL,
    "DEVICE_ID" character varying(255) NOT NULL,
    "ENABLED" boolean NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone
);


ALTER TABLE public."SYNCTHING_DEVICE" OWNER TO postgres;

--
-- Name: TARGET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TARGET" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "TYPE" character varying(255),
    "IS_KEY_BASED" boolean,
    "STATE" character varying(255),
    "STATE_REASON" character varying(255),
    "IS_DEPLOYMENT_CREATED" boolean,
    "OS_NAME" character varying(255),
    "HOST" character varying(255),
    "PORT" integer,
    "PLATFORM" character varying(255),
    "PRODUCT_COPY_DESTINATION" character varying(255),
    "ANSIBLE_CONNECTION" character varying(255),
    "ANSIBLE_SHELL_TYPE" character varying(255),
    "REMOTE_KEY" bigint,
    "PARENT" bigint NOT NULL,
    "TARGET_GROUP" bigint,
    "USERNAME" character varying(256),
    "USER_TYPE" character varying(255),
    "USER_DOMAIN" character varying(256),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."TARGET" OWNER TO postgres;

--
-- Name: TARGET_CONFIGURATION_SNAPSHOT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TARGET_CONFIGURATION_SNAPSHOT" (
    "ID" bigint NOT NULL,
    "TARGET_ID" bigint
);


ALTER TABLE public."TARGET_CONFIGURATION_SNAPSHOT" OWNER TO postgres;

--
-- Name: TARGET_GROUP; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TARGET_GROUP" (
    "ID" bigint NOT NULL,
    "NAME" character varying(255) NOT NULL
);


ALTER TABLE public."TARGET_GROUP" OWNER TO postgres;

--
-- Name: TARGET_GROUP_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."TARGET_GROUP_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."TARGET_GROUP_ID_seq" OWNER TO postgres;

--
-- Name: TARGET_GROUP_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."TARGET_GROUP_ID_seq" OWNED BY public."TARGET_GROUP"."ID";


--
-- Name: TARGET_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."TARGET_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."TARGET_ID_seq" OWNER TO postgres;

--
-- Name: TARGET_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."TARGET_ID_seq" OWNED BY public."TARGET"."ID";


--
-- Name: USER; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."USER" (
    "ID" bigint NOT NULL,
    "ACTIVE" boolean,
    "API_ENABLED" boolean,
    "API_KEY" character varying(255),
    "CREATED" timestamp without time zone,
    "DELETED" boolean,
    "DEPARTMENT" character varying(255),
    "DOMAIN" character varying(190),
    "EMAIL" character varying(190),
    "FIRST_NAME" character varying(255),
    "LAST_NAME" character varying(255),
    "MOBILE" character varying(255),
    "MODIFIED" timestamp without time zone,
    "ORIGIN_ID" character varying(32),
    "ORIGIN_LOCATOR" character varying(32) NOT NULL,
    "PASSWORD" character varying(255),
    "PHONE" character varying(255),
    "SALT" character varying(255),
    "TITLE" character varying(255),
    "USERNAME" character varying(190),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."USER" OWNER TO postgres;

--
-- Name: USER_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."USER_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."USER_ID_seq" OWNER TO postgres;

--
-- Name: USER_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."USER_ID_seq" OWNED BY public."USER"."ID";


--
-- Name: USER_ROLE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."USER_ROLE" (
    "USER" bigint NOT NULL,
    "ROLE" bigint NOT NULL
);


ALTER TABLE public."USER_ROLE" OWNER TO postgres;

--
-- Name: USER_SESSION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."USER_SESSION" (
    "ID" bigint NOT NULL,
    "AUTHENTICATOR" character varying(255),
    "CREATED" timestamp without time zone,
    "IP_ADDRESS" character varying(255),
    "MODIFIED" timestamp without time zone,
    "SESSION_ID" character varying(190),
    "SESSION_TOKEN" character varying(255),
    "SSO_ID" character varying(255),
    "USE_CONCURRENT_USER" boolean,
    "USER_ACTIVE" timestamp without time zone,
    "USER_AGENT" character varying(255),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "NODE" bigint,
    "USER" bigint
);


ALTER TABLE public."USER_SESSION" OWNER TO postgres;

--
-- Name: USER_SESSION_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."USER_SESSION_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."USER_SESSION_ID_seq" OWNER TO postgres;

--
-- Name: USER_SESSION_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."USER_SESSION_ID_seq" OWNED BY public."USER_SESSION"."ID";


--
-- Name: USER_SESSION_SAML_SESSION_INDEX; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."USER_SESSION_SAML_SESSION_INDEX" (
    "USER_SESSION_ID" bigint NOT NULL,
    "SESSION_INDEX" character varying(255)
);


ALTER TABLE public."USER_SESSION_SAML_SESSION_INDEX" OWNER TO postgres;

--
-- Name: USER_WATERMARK_MONITOR; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."USER_WATERMARK_MONITOR" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "SESSION_COUNT" bigint,
    "USER_COUNT" bigint,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."USER_WATERMARK_MONITOR" OWNER TO postgres;

--
-- Name: USER_WATERMARK_MONITOR_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."USER_WATERMARK_MONITOR_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."USER_WATERMARK_MONITOR_ID_seq" OWNER TO postgres;

--
-- Name: USER_WATERMARK_MONITOR_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."USER_WATERMARK_MONITOR_ID_seq" OWNED BY public."USER_WATERMARK_MONITOR"."ID";


--
-- Name: VIEW; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VIEW" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "EXTENSION" character varying(255),
    "FOCUSED" boolean,
    "HANDLE" character varying(255),
    "INDEX" bigint,
    "MODIFIED" timestamp without time zone,
    "URL" character varying(2000),
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "USER" bigint,
    "VIEWPORT" bigint
);


ALTER TABLE public."VIEW" OWNER TO postgres;

--
-- Name: VIEWPORT; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VIEWPORT" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "HEIGHT" integer,
    "MODIFIED" timestamp without time zone,
    "VERSION_ID" integer NOT NULL,
    "WIDTH" integer,
    "CREATED_BY" bigint,
    "FOCUSED" bigint,
    "MODIFIED_BY" bigint,
    "USER" bigint,
    "WORKSPACE" bigint,
    "INDEX" character varying(255)
);


ALTER TABLE public."VIEWPORT" OWNER TO postgres;

--
-- Name: VIEWPORT_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VIEWPORT_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VIEWPORT_ID_seq" OWNER TO postgres;

--
-- Name: VIEWPORT_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VIEWPORT_ID_seq" OWNED BY public."VIEWPORT"."ID";


--
-- Name: VIEW_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VIEW_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VIEW_ID_seq" OWNER TO postgres;

--
-- Name: VIEW_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VIEW_ID_seq" OWNED BY public."VIEW"."ID";


--
-- Name: VIEW_PROPERTY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VIEW_PROPERTY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "HANDLE" character varying(255),
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(255),
    "VALUE" character varying(5000),
    "VERSION_ID" integer NOT NULL,
    "VIEW" character varying(255),
    "WORKBENCH" character varying(255),
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."VIEW_PROPERTY" OWNER TO postgres;

--
-- Name: VIEW_PROPERTY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VIEW_PROPERTY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VIEW_PROPERTY_ID_seq" OWNER TO postgres;

--
-- Name: VIEW_PROPERTY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VIEW_PROPERTY_ID_seq" OWNED BY public."VIEW_PROPERTY"."ID";


--
-- Name: VIRTUAL_DIRECTORY; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VIRTUAL_DIRECTORY" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MODIFIED" timestamp without time zone,
    "NAME" character varying(190) NOT NULL,
    "UNIQUE_NAME" character varying(190) NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "PARENT" bigint
);


ALTER TABLE public."VIRTUAL_DIRECTORY" OWNER TO postgres;

--
-- Name: VIRTUAL_DIRECTORY_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VIRTUAL_DIRECTORY_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VIRTUAL_DIRECTORY_ID_seq" OWNER TO postgres;

--
-- Name: VIRTUAL_DIRECTORY_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VIRTUAL_DIRECTORY_ID_seq" OWNED BY public."VIRTUAL_DIRECTORY"."ID";


--
-- Name: VISUAL_WORKFLOW_JOB; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VISUAL_WORKFLOW_JOB" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "ICON" character varying(255),
    "DESCRIPTION" text,
    "ENABLED" boolean,
    "PRIORITY" integer,
    "SCHEDULE_TYPE_ID" character varying(255) NOT NULL,
    "SCHEDULE_TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "PATTERN_TYPE_ID" character varying(255),
    "PATTERN_TYPE_EXTENSION_ID" character varying(255),
    "PARENT" bigint NOT NULL,
    "SCHEDULE" character varying(255),
    "TIME_ZONE" character varying(255),
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."VISUAL_WORKFLOW_JOB" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_JOB_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VISUAL_WORKFLOW_JOB_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VISUAL_WORKFLOW_JOB_ID_seq" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_JOB_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VISUAL_WORKFLOW_JOB_ID_seq" OWNED BY public."VISUAL_WORKFLOW_JOB"."ID";


--
-- Name: VISUAL_WORKFLOW_JOB_RUN; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VISUAL_WORKFLOW_JOB_RUN" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "SUBMITTED" timestamp without time zone NOT NULL,
    "START" timestamp without time zone,
    "END" timestamp without time zone,
    "JOB" bigint NOT NULL,
    "NODE" bigint,
    "STATUS" character varying(16) NOT NULL,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."VISUAL_WORKFLOW_JOB_RUN" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_JOB_RUN_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VISUAL_WORKFLOW_JOB_RUN_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VISUAL_WORKFLOW_JOB_RUN_ID_seq" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_JOB_RUN_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VISUAL_WORKFLOW_JOB_RUN_ID_seq" OWNED BY public."VISUAL_WORKFLOW_JOB_RUN"."ID";


--
-- Name: VISUAL_WORKFLOW_NODE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VISUAL_WORKFLOW_NODE" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "NAME" character varying(255) NOT NULL,
    "UUID" character varying(255) NOT NULL,
    "X_POSITION" integer NOT NULL,
    "Y_POSITION" integer NOT NULL,
    "NODE_TYPE_ID" character varying(255) NOT NULL,
    "NODE_TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "JOB" bigint,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."VISUAL_WORKFLOW_NODE" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_NODE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VISUAL_WORKFLOW_NODE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VISUAL_WORKFLOW_NODE_ID_seq" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_NODE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VISUAL_WORKFLOW_NODE_ID_seq" OWNED BY public."VISUAL_WORKFLOW_NODE"."ID";


--
-- Name: VISUAL_WORKFLOW_SOCKET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VISUAL_WORKFLOW_SOCKET" (
    "ID" bigint NOT NULL,
    "VERSION_ID" integer NOT NULL,
    "NAME" character varying(255),
    "KEY_NAME" character varying(255) NOT NULL,
    "UUID" character varying(255) NOT NULL,
    "CONFIGURATION" text,
    "SOCKET_TYPE_ID" character varying(255) NOT NULL,
    "SOCKET_TYPE_EXTENSION_ID" character varying(255) NOT NULL,
    "NODE" bigint,
    "CREATED" timestamp without time zone,
    "CREATED_BY" bigint,
    "MODIFIED" timestamp without time zone,
    "MODIFIED_BY" bigint
);


ALTER TABLE public."VISUAL_WORKFLOW_SOCKET" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_SOCKET_CONNECTION; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VISUAL_WORKFLOW_SOCKET_CONNECTION" (
    "SOURCE" bigint NOT NULL,
    "DESTINATION" bigint NOT NULL
);


ALTER TABLE public."VISUAL_WORKFLOW_SOCKET_CONNECTION" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_SOCKET_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."VISUAL_WORKFLOW_SOCKET_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."VISUAL_WORKFLOW_SOCKET_ID_seq" OWNER TO postgres;

--
-- Name: VISUAL_WORKFLOW_SOCKET_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."VISUAL_WORKFLOW_SOCKET_ID_seq" OWNED BY public."VISUAL_WORKFLOW_SOCKET"."ID";


--
-- Name: VMWARE_TARGET; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."VMWARE_TARGET" (
    "ID" bigint NOT NULL,
    "TEMPLATE_NAME" character varying(255),
    "VM_NAME" character varying(255),
    "INITIAL_STATE" character varying(255),
    "NETWORK" character varying(255),
    "WAIT_FOR_IP" boolean
);


ALTER TABLE public."VMWARE_TARGET" OWNER TO postgres;

--
-- Name: WORKSPACE; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."WORKSPACE" (
    "ID" bigint NOT NULL,
    "CREATED" timestamp without time zone,
    "MOBILE" boolean,
    "MODIFIED" timestamp without time zone,
    "VERSION_ID" integer NOT NULL,
    "WORKBENCH" character varying(190),
    "CREATED_BY" bigint,
    "MODIFIED_BY" bigint,
    "PERSPECTIVE" bigint,
    "USER" bigint
);


ALTER TABLE public."WORKSPACE" OWNER TO postgres;

--
-- Name: WORKSPACE_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."WORKSPACE_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."WORKSPACE_ID_seq" OWNER TO postgres;

--
-- Name: WORKSPACE_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."WORKSPACE_ID_seq" OWNED BY public."WORKSPACE"."ID";


--
-- Name: license_analytics_by_feature_product_key_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_feature_product_key_summary AS
 WITH license_base AS (
         SELECT l."ID" AS license_id,
            l."FEATURE",
            l."PRODUCT_KEY",
            (l."ACTIVATION_LIMIT")::bigint AS activation_limit,
            l."NUMBER" AS number,
            l."ACTIVATED_OFFLINE",
            l."PURCHASED",
            l."EXPIRY_DATE"
           FROM public."LICENSE" l
          WHERE (l."PURCHASED" = true)
        ), license_details AS (
         SELECT lb.license_id,
            lb.activation_limit,
            lb.number,
            lb."ACTIVATED_OFFLINE",
            lb."EXPIRY_DATE",
            pk."KEY" AS product_key,
            pk."ID" AS product_key_id,
            pk."LICENCED_TO" AS licensed_to,
            pk."ACTIVATED",
                CASE
                    WHEN ((pk."CHECKED_OUT_HARDWARE_ID")::text IS DISTINCT FROM public.get_hardware_id()) THEN (('Other- '::text || (pk."CHECKED_OUT_HARDWARE_ID")::text))::character varying
                    ELSE pk."CHECKED_OUT_HARDWARE_ID"
                END AS checked_out_hardware_id,
            pk."DISABLED",
            f."ID" AS feature_id,
            f."NAME" AS feature_name,
            p."ID" AS product_id,
            p."NAME" AS product_name,
            p."LICENSING_MODE",
            p."USE_FEATURE_LEVEL_MAINTENANCE",
                CASE
                    WHEN ((p."LICENSING_MODE")::text = 'DYNAMIC'::text) THEN lb.activation_limit
                    WHEN ((p."LICENSING_MODE")::text = 'STATIC'::text) THEN (lb.number)::bigint
                    ELSE NULL::bigint
                END AS effective_limit,
                CASE
                    WHEN (lb."EXPIRY_DATE" <= now()) THEN (1)::bigint
                    ELSE NULL::bigint
                END AS "EXPIRED"
           FROM (((license_base lb
             JOIN public."PRODUCT_KEY" pk ON ((lb."PRODUCT_KEY" = pk."ID")))
             JOIN public."FEATURE" f ON ((lb."FEATURE" = f."ID")))
             JOIN public."PRODUCT" p ON ((f."PRODUCT" = p."ID")))
          WHERE (pk."DISABLED" = false)
        ), usage_details AS (
         SELECT ld.feature_id,
            ld.product_key_id,
            ((COALESCE(sum(
                CASE
                    WHEN ((COALESCE(ld."ACTIVATED", false) = false) AND (ld.checked_out_hardware_id IS NOT NULL)) THEN
                    CASE
                        WHEN (((ld.checked_out_hardware_id)::text IS DISTINCT FROM public.get_hardware_id()) AND (ld.effective_limit IS NULL)) THEN (public.get_infinite_num())::bigint
                        ELSE COALESCE(ld.effective_limit, (0)::bigint)
                    END
                    ELSE (0)::bigint
                END), (0)::numeric) + (COALESCE(count(a."ID"), (0)::bigint))::numeric))::integer AS used_count
           FROM (license_details ld
             LEFT JOIN public."ACTIVATION" a ON ((a."LICENSE" = ld.license_id)))
          WHERE (((COALESCE(ld."ACTIVATED", false) = false) AND (ld.checked_out_hardware_id IS NOT NULL)) OR (a."ID" IS NOT NULL))
          GROUP BY ld.feature_id, ld.product_key_id
        ), license_availability AS (
         SELECT ld.product_name AS "PRODUCT_NAME",
            ld.feature_name AS "FEATURE_NAME",
            ld.product_key AS "PRODUCT_KEY",
            ld.licensed_to AS "LICENSED_TO",
                CASE
                    WHEN ((ld.effective_limit IS NULL) OR (ld.effective_limit = 0)) THEN (public.get_infinite_num())::bigint
                    ELSE ld.effective_limit
                END AS "TOTAL",
            ld.feature_id,
            ud.product_key_id,
            COALESCE(ud.used_count, 0) AS "USED",
            ld.checked_out_hardware_id,
            ld."ACTIVATED",
            ld."LICENSING_MODE",
            ld."ACTIVATED_OFFLINE",
            ld.product_id,
            ld."EXPIRED",
                CASE
                    WHEN (ud.used_count = public.get_infinite_num()) THEN (0)::bigint
                    WHEN ((ld.effective_limit IS NULL) OR (ld.effective_limit = 0)) THEN (public.get_infinite_num())::bigint
                    WHEN (ld."EXPIRED" IS NULL) THEN COALESCE((ld.effective_limit - COALESCE(ud.used_count, 0)), (0)::bigint)
                    ELSE (0)::bigint
                END AS "AVAILABLE"
           FROM (license_details ld
             LEFT JOIN usage_details ud ON (((ud.feature_id = ld.feature_id) AND (ud.product_key_id = ld.product_key_id))))
        )
 SELECT la."PRODUCT_NAME",
    la."FEATURE_NAME",
    la."PRODUCT_KEY",
    la."LICENSED_TO",
    la."TOTAL",
    la."USED",
    la."AVAILABLE",
    la."EXPIRED",
    public.get_checked_out_status(la.checked_out_hardware_id, la."ACTIVATED", la."LICENSING_MODE", la."ACTIVATED_OFFLINE") AS "CHECKED_OUT",
    la.checked_out_hardware_id AS "CHECKED_OUT_HARDWARE_ID",
    round(((la."USED")::numeric / (NULLIF((la."USED" + la."AVAILABLE"), 0))::numeric), 2) AS "USAGE",
    la.product_id AS "PRODUCT_ID",
    la.feature_id AS "FEATURE_ID"
   FROM license_availability la
  ORDER BY la."PRODUCT_NAME", la."FEATURE_NAME";


ALTER VIEW public.license_analytics_by_feature_product_key_summary OWNER TO postgres;

--
-- Name: license_analytics_by_feature_feature_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_feature_feature_summary AS
 WITH total_licenses AS (
         SELECT l_1."FEATURE" AS feature_id,
            public.evaluate_licenses(count(*) FILTER (WHERE ((((p_1."LICENSING_MODE")::text = 'DYNAMIC'::text) AND ((l_1."ACTIVATION_LIMIT" IS NULL) OR (l_1."ACTIVATION_LIMIT" = 0))) OR (((p_1."LICENSING_MODE")::text = 'STATIC'::text) AND ((l_1."NUMBER" IS NULL) OR (l_1."NUMBER" = 0))))), count(*) FILTER (WHERE ((((p_1."LICENSING_MODE")::text = 'DYNAMIC'::text) AND (l_1."ACTIVATION_LIMIT" > 0)) OR (((p_1."LICENSING_MODE")::text = 'STATIC'::text) AND (l_1."NUMBER" > 0)))), (COALESCE(sum(
                CASE
                    WHEN (((p_1."LICENSING_MODE")::text = 'DYNAMIC'::text) AND (l_1."ACTIVATION_LIMIT" > 0)) THEN (l_1."ACTIVATION_LIMIT")::bigint
                    WHEN (((p_1."LICENSING_MODE")::text = 'STATIC'::text) AND (l_1."NUMBER" > 0)) THEN (l_1."NUMBER")::bigint
                    ELSE (0)::bigint
                END), (0)::numeric))::bigint) AS total_licenses
           FROM ((public."LICENSE" l_1
             JOIN public."PRODUCT_KEY" pk_1 ON ((l_1."PRODUCT_KEY" = pk_1."ID")))
             JOIN public."PRODUCT" p_1 ON ((pk_1."PRODUCT" = p_1."ID")))
          WHERE ((pk_1."DISABLED" = false) AND (l_1."PURCHASED" = true))
          GROUP BY l_1."FEATURE"
        ), used_licenses AS (
         SELECT pk_view."FEATURE_ID" AS feature_id,
            public.evaluate_used_licenses(count(*) FILTER (WHERE ((pk_view."USED" = public.get_infinite_num()) AND ((pk_view."USED" > 0) OR ((pk_view."CHECKED_OUT_HARDWARE_ID")::text IS DISTINCT FROM public.get_hardware_id())))), count(*) FILTER (WHERE ((pk_view."USED" > 0) AND (pk_view."USED" > 0))), (COALESCE(sum(
                CASE
                    WHEN ((pk_view."USED" > 0) AND (pk_view."USED" > 0)) THEN (pk_view."USED")::bigint
                    ELSE (0)::bigint
                END), (0)::numeric))::bigint, (COALESCE(sum(
                CASE
                    WHEN ((pk_view."TOTAL" = public.get_infinite_num()) AND (pk_view."USED" > 0)) THEN (pk_view."USED")::bigint
                    ELSE (0)::bigint
                END), (0)::numeric))::bigint) AS used_licenses
           FROM public.license_analytics_by_feature_product_key_summary pk_view
          GROUP BY pk_view."FEATURE_ID"
        ), available_licenses AS (
         SELECT pk_view."FEATURE_ID" AS feature_id,
            public.evaluate_licenses(count(*) FILTER (WHERE (pk_view."AVAILABLE" = public.get_infinite_num())), count(*) FILTER (WHERE ((pk_view."AVAILABLE" >= 0) AND (pk_view."AVAILABLE" < public.get_infinite_num()))), (COALESCE(sum(
                CASE
                    WHEN ((pk_view."AVAILABLE" >= 0) AND (pk_view."AVAILABLE" < public.get_infinite_num())) THEN pk_view."AVAILABLE"
                    ELSE (0)::bigint
                END), (0)::numeric))::bigint) AS available_licenses
           FROM public.license_analytics_by_feature_product_key_summary pk_view
          GROUP BY pk_view."FEATURE_ID"
        ), license_stats AS (
         SELECT f_1."ID" AS feature_id,
            tl.total_licenses AS total,
            ul.used_licenses AS used_count,
            al.available_licenses AS available,
            COALESCE(sum(pk_view."EXPIRED"), (0)::numeric) AS expired
           FROM ((((public."FEATURE" f_1
             LEFT JOIN public.license_analytics_by_feature_product_key_summary pk_view ON ((f_1."ID" = pk_view."FEATURE_ID")))
             LEFT JOIN total_licenses tl ON ((tl.feature_id = f_1."ID")))
             LEFT JOIN used_licenses ul ON ((ul.feature_id = f_1."ID")))
             LEFT JOIN available_licenses al ON ((al.feature_id = f_1."ID")))
          GROUP BY f_1."ID", tl.total_licenses, ul.used_licenses, al.available_licenses
        ), checkout_stats AS (
         SELECT pk_view."PRODUCT_ID",
            pk_view."FEATURE_ID",
                CASE
                    WHEN (count(DISTINCT pk_view."CHECKED_OUT") = 1) THEN (max((pk_view."CHECKED_OUT")::text))::character varying
                    ELSE 'Some'::character varying
                END AS "CHECKED_OUT"
           FROM (public.license_analytics_by_feature_product_key_summary pk_view
             JOIN license_stats ls_1 ON ((ls_1.feature_id = pk_view."FEATURE_ID")))
          GROUP BY pk_view."PRODUCT_ID", pk_view."FEATURE_ID"
        ), total_pk_count AS (
         SELECT pk_view."PRODUCT_ID",
            pk_view."FEATURE_ID",
            count(*) AS pk_count
           FROM (public.license_analytics_by_feature_product_key_summary pk_view
             JOIN license_stats ls_1 ON ((ls_1.feature_id = pk_view."FEATURE_ID")))
          GROUP BY pk_view."PRODUCT_ID", pk_view."FEATURE_ID"
        )
 SELECT p."ID" AS "PRODUCT_ID",
    f."ID" AS "FEATURE_ID",
    p."NAME" AS "PRODUCT_NAME",
    f."NAME" AS "FEATURE_NAME",
    ls.total AS "TOTAL",
    ls.used_count AS "USED",
    ls.available AS "AVAILABLE",
    ls.expired AS "EXPIRED",
    cs."CHECKED_OUT",
        CASE
            WHEN (ls.total = '-1'::integer) THEN (- (1)::numeric)
            WHEN ((ls.total = 0) AND (ls.expired = (pk_total.pk_count)::numeric)) THEN NULL::numeric
            WHEN (ls.total = 0) THEN (0)::numeric
            ELSE round(((ls.used_count)::numeric / (NULLIF((ls.used_count + ls.available), 0))::numeric), 2)
        END AS "USAGE"
   FROM ((((((public."PRODUCT" p
     JOIN public."FEATURE" f ON ((p."ID" = f."PRODUCT")))
     JOIN license_stats ls ON ((f."ID" = ls.feature_id)))
     JOIN public."LICENSE" l ON ((f."ID" = l."FEATURE")))
     JOIN public."PRODUCT_KEY" pk ON ((l."PRODUCT_KEY" = pk."ID")))
     LEFT JOIN checkout_stats cs ON (((cs."PRODUCT_ID" = p."ID") AND (cs."FEATURE_ID" = f."ID"))))
     LEFT JOIN total_pk_count pk_total ON (((pk_total."PRODUCT_ID" = p."ID") AND (pk_total."FEATURE_ID" = f."ID"))))
  WHERE (l."PURCHASED" AND (NOT pk."DISABLED") AND ((f."NAME")::text <> 'Maintenance'::text))
  GROUP BY p."ID", f."ID", p."NAME", f."NAME", ls.total, ls.used_count, ls.available, ls.expired, cs."CHECKED_OUT", pk_total.pk_count
  ORDER BY p."ID";


ALTER VIEW public.license_analytics_by_feature_feature_summary OWNER TO postgres;

--
-- Name: license_analytics_by_feature_host_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_feature_host_summary AS
 SELECT row_number() OVER () AS "ID",
        CASE
            WHEN ("ACTIVATION"."HOSTNAME" IS NULL) THEN ("ACTIVATION"."IP_ADDRESS")::text
            ELSE concat("ACTIVATION"."HOSTNAME", ' (', "ACTIVATION"."IP_ADDRESS", ')')
        END AS "HOST_INFO",
    count("ACTIVATION"."ID") AS "USED",
    "PRODUCT"."NAME" AS "PRODUCT_NAME",
    "FEATURE"."NAME" AS "FEATURE_NAME",
    "PRODUCT_KEY"."KEY" AS "PRODUCT_KEY",
    "ACTIVATION"."HOSTNAME" AS "HOST_NAME",
    "ACTIVATION"."IP_ADDRESS" AS "HOST_IP_ADDRESS",
    "PRODUCT"."ID" AS "PRODUCT_ID",
    "FEATURE"."ID" AS "FEATURE_ID"
   FROM ((((public."ACTIVATION"
     JOIN public."PRODUCT_KEY" ON (("ACTIVATION"."PRODUCT_KEY" = "PRODUCT_KEY"."ID")))
     JOIN public."LICENSE" ON (("LICENSE"."ID" = "ACTIVATION"."LICENSE")))
     JOIN public."FEATURE" ON (("FEATURE"."ID" = "LICENSE"."FEATURE")))
     JOIN public."PRODUCT" ON (("PRODUCT_KEY"."PRODUCT" = "PRODUCT"."ID")))
  WHERE (NOT "PRODUCT_KEY"."DISABLED")
  GROUP BY "PRODUCT"."NAME", "FEATURE"."NAME", "PRODUCT_KEY"."KEY", "ACTIVATION"."HOSTNAME", "ACTIVATION"."IP_ADDRESS", "ACTIVATION"."ID", "PRODUCT"."ID", "FEATURE"."ID"
  ORDER BY
        CASE
            WHEN ("ACTIVATION"."HOSTNAME" IS NULL) THEN ("ACTIVATION"."IP_ADDRESS")::text
            ELSE concat("ACTIVATION"."HOSTNAME", ' (', "ACTIVATION"."IP_ADDRESS", ')')
        END;


ALTER VIEW public.license_analytics_by_feature_host_summary OWNER TO postgres;

--
-- Name: license_analytics_by_host_feature_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_host_feature_summary AS
 SELECT row_number() OVER () AS "ID",
    f."NAME" AS "FEATURE_NAME",
    a."ACTIVE_UNTIL",
    a."HOSTNAME" AS "HOST_NAME",
    a."IP_ADDRESS" AS "HOST_IP_ADDRESS",
    pk."KEY" AS "PRODUCT_KEY"
   FROM ((((public."ACTIVATION" a
     JOIN public."PRODUCT_KEY" pk ON ((a."PRODUCT_KEY" = pk."ID")))
     JOIN public."LICENSE" l ON ((a."LICENSE" = l."ID")))
     JOIN public."FEATURE" f ON ((l."FEATURE" = f."ID")))
     JOIN public."PRODUCT" p ON ((pk."PRODUCT" = p."ID")))
  WHERE ((NOT pk."DISABLED") AND (NOT ((f."NAME")::text = 'Maintenance'::text)))
  ORDER BY f."NAME";


ALTER VIEW public.license_analytics_by_host_feature_summary OWNER TO postgres;

--
-- Name: license_analytics_by_host_host_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_host_host_summary AS
 SELECT max((a."HOSTNAME")::text) AS "HOST_NAME",
    a."IP_ADDRESS" AS "HOST_IP_ADDRESS",
    string_agg(DISTINCT (p."NAME")::text, ', '::text ORDER BY (p."NAME")::text) AS "PRODUCT_NAME",
    string_agg(DISTINCT (k."LICENCED_TO")::text, ', '::text ORDER BY (k."LICENCED_TO")::text) AS "LICENSED_TO"
   FROM ((public."ACTIVATION" a
     JOIN public."PRODUCT_KEY" k ON ((k."ID" = a."PRODUCT_KEY")))
     JOIN public."PRODUCT" p ON ((k."PRODUCT" = p."ID")))
  WHERE (NOT k."DISABLED")
  GROUP BY a."IP_ADDRESS";


ALTER VIEW public.license_analytics_by_host_host_summary OWNER TO postgres;

--
-- Name: license_analytics_by_host_product_key_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.license_analytics_by_host_product_key_summary AS
 SELECT DISTINCT pk."KEY" AS "PRODUCT_KEY",
    p."NAME" AS "PRODUCT_NAME",
    pk."LICENCED_TO" AS "LICENSED_TO",
    a."HOSTNAME" AS "HOST_NAME",
    a."IP_ADDRESS" AS "HOST_IP_ADDRESS"
   FROM ((public."ACTIVATION" a
     JOIN public."PRODUCT_KEY" pk ON ((a."PRODUCT_KEY" = pk."ID")))
     JOIN public."PRODUCT" p ON ((pk."PRODUCT" = p."ID")))
  WHERE (NOT pk."DISABLED");


ALTER VIEW public.license_analytics_by_host_product_key_summary OWNER TO postgres;

--
-- Name: ACTIVATION ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION" ALTER COLUMN "ID" SET DEFAULT nextval('public."ACTIVATION_ID_seq"'::regclass);


--
-- Name: ACTIVATION_HISTORY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_HISTORY" ALTER COLUMN "ID" SET DEFAULT nextval('public."ACTIVATION_HISTORY_ID_seq"'::regclass);


--
-- Name: ACTIVATION_SERVER_DATA ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_SERVER_DATA" ALTER COLUMN "ID" SET DEFAULT nextval('public."ACTIVATION_SERVER_DATA_ID_seq"'::regclass);


--
-- Name: ADVANCED_SEARCH ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ADVANCED_SEARCH" ALTER COLUMN "ID" SET DEFAULT nextval('public."ADVANCED_SEARCH_ID_seq"'::regclass);


--
-- Name: APP ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."APP" ALTER COLUMN "ID" SET DEFAULT nextval('public."APP_ID_seq"'::regclass);


--
-- Name: ATTRIBUTE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE" ALTER COLUMN "ID" SET DEFAULT nextval('public."ATTRIBUTE_ID_seq"'::regclass);


--
-- Name: ATTRIBUTE_PARAMETER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER" ALTER COLUMN "ID" SET DEFAULT nextval('public."ATTRIBUTE_PARAMETER_ID_seq"'::regclass);


--
-- Name: ATTRIBUTE_PARAMETER_SET ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET" ALTER COLUMN "ID" SET DEFAULT nextval('public."ATTRIBUTE_PARAMETER_SET_ID_seq"'::regclass);


--
-- Name: BUNDLE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BUNDLE" ALTER COLUMN "ID" SET DEFAULT nextval('public."BUNDLE_ID_seq"'::regclass);


--
-- Name: CHOICE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE" ALTER COLUMN "ID" SET DEFAULT nextval('public."CHOICE_ID_seq"'::regclass);


--
-- Name: CHOICE_LIST ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE_LIST" ALTER COLUMN "ID" SET DEFAULT nextval('public."CHOICE_LIST_ID_seq"'::regclass);


--
-- Name: COMPONENT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT" ALTER COLUMN "ID" SET DEFAULT nextval('public."COMPONENT_ID_seq"'::regclass);


--
-- Name: COMPONENT_PROCESS ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT_PROCESS" ALTER COLUMN "ID" SET DEFAULT nextval('public."COMPONENT_PROCESS_ID_seq"'::regclass);


--
-- Name: CONFIGURATION ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION" ALTER COLUMN "ID" SET DEFAULT nextval('public."CONFIGURATION_ID_seq"'::regclass);


--
-- Name: CONFIGURATION_SNAPSHOT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT" ALTER COLUMN "ID" SET DEFAULT nextval('public."CONFIGURATION_SNAPSHOT_ID_seq"'::regclass);


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY" ALTER COLUMN "ID" SET DEFAULT nextval('public."CONFIGURATION_SNAPSHOT_HISTORY_ID_seq"'::regclass);


--
-- Name: CUSTOM_PANEL_FILE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CUSTOM_PANEL_FILE" ALTER COLUMN "ID" SET DEFAULT nextval('public."CUSTOM_PANEL_FILE_ID_seq"'::regclass);


--
-- Name: DEPLOYMENT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT" ALTER COLUMN "ID" SET DEFAULT nextval('public."DEPLOYMENT_ID_seq"'::regclass);


--
-- Name: DEPLOYMENT_COMPONENT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT" ALTER COLUMN "ID" SET DEFAULT nextval('public."DEPLOYMENT_COMPONENT_ID_seq"'::regclass);


--
-- Name: DISPLAY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY" ALTER COLUMN "ID" SET DEFAULT nextval('public."DISPLAY_ID_seq"'::regclass);


--
-- Name: ENTITY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_ID_seq"'::regclass);


--
-- Name: ENTITY_CONNECTION ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_CONNECTION_ID_seq"'::regclass);


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq"'::regclass);


--
-- Name: ENTITY_CONNECTION_INSTANCE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_CONNECTION_INSTANCE_ID_seq"'::regclass);


--
-- Name: ENTITY_FORM ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_FORM_ID_seq"'::regclass);


--
-- Name: ENTITY_FORM_ATTRIBUTE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_FORM_ATTRIBUTE_ID_seq"'::regclass);


--
-- Name: ENTITY_INSTANCE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_INSTANCE" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_INSTANCE_ID_seq"'::regclass);


--
-- Name: ENTITY_MANAGER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER" ALTER COLUMN "ID" SET DEFAULT nextval('public."ENTITY_MANAGER_ID_seq"'::regclass);


--
-- Name: FEATURE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE" ALTER COLUMN "ID" SET DEFAULT nextval('public."FEATURE_ID_seq"'::regclass);


--
-- Name: FEDERATED_SEARCH ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEDERATED_SEARCH" ALTER COLUMN "ID" SET DEFAULT nextval('public."FEDERATED_SEARCH_ID_seq"'::regclass);


--
-- Name: FILE_SYSTEM ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FILE_SYSTEM" ALTER COLUMN "ID" SET DEFAULT nextval('public."FILE_SYSTEM_ID_seq"'::regclass);


--
-- Name: GATEWAY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GATEWAY" ALTER COLUMN "ID" SET DEFAULT nextval('public."GATEWAY_ID_seq"'::regclass);


--
-- Name: HOST ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOST" ALTER COLUMN "ID" SET DEFAULT nextval('public."HOST_ID_seq"'::regclass);


--
-- Name: HOTKEY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOTKEY" ALTER COLUMN "ID" SET DEFAULT nextval('public."HOTKEY_ID_seq"'::regclass);


--
-- Name: JOB ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB" ALTER COLUMN "ID" SET DEFAULT nextval('public."JOB_ID_seq"'::regclass);


--
-- Name: LICENSE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE" ALTER COLUMN "ID" SET DEFAULT nextval('public."LICENSE_ID_seq"'::regclass);


--
-- Name: LICENSE_KEY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE_KEY" ALTER COLUMN "ID" SET DEFAULT nextval('public."LICENSE_KEY_ID_seq"'::regclass);


--
-- Name: MAIL_RECIPIENT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_RECIPIENT" ALTER COLUMN "ID" SET DEFAULT nextval('public."MAIL_RECIPIENT_ID_seq"'::regclass);


--
-- Name: MAIL_SERVER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_SERVER" ALTER COLUMN "ID" SET DEFAULT nextval('public."MAIL_SERVER_ID_seq"'::regclass);


--
-- Name: MANAGER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MANAGER" ALTER COLUMN "ID" SET DEFAULT nextval('public."MANAGER_ID_seq"'::regclass);


--
-- Name: MONITOR ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MONITOR" ALTER COLUMN "ID" SET DEFAULT nextval('public."MONITOR_ID_seq"'::regclass);


--
-- Name: NODE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE" ALTER COLUMN "ID" SET DEFAULT nextval('public."NODE_ID_seq"'::regclass);


--
-- Name: NODE_STATUS ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS" ALTER COLUMN "ID" SET DEFAULT nextval('public."NODE_STATUS_ID_seq"'::regclass);


--
-- Name: OGP_FRAME ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_FRAME" ALTER COLUMN "ID" SET DEFAULT nextval('public."OGP_FRAME_ID_seq"'::regclass);


--
-- Name: OGP_MENU_GROUP ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_MENU_GROUP" ALTER COLUMN "ID" SET DEFAULT nextval('public."OGP_MENU_GROUP_ID_seq"'::regclass);


--
-- Name: PARAMETER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER" ALTER COLUMN "ID" SET DEFAULT nextval('public."PARAMETER_ID_seq"'::regclass);


--
-- Name: PARAMETER_SET ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER_SET" ALTER COLUMN "ID" SET DEFAULT nextval('public."PARAMETER_SET_ID_seq"'::regclass);


--
-- Name: PERMISSION ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION" ALTER COLUMN "ID" SET DEFAULT nextval('public."PERMISSION_ID_seq"'::regclass);


--
-- Name: PERSPECTIVE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE" ALTER COLUMN "ID" SET DEFAULT nextval('public."PERSPECTIVE_ID_seq"'::regclass);


--
-- Name: PERSPECTIVE_COLUMN ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_COLUMN" ALTER COLUMN "ID" SET DEFAULT nextval('public."PERSPECTIVE_COLUMN_ID_seq"'::regclass);


--
-- Name: PERSPECTIVE_FIELD ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_FIELD" ALTER COLUMN "ID" SET DEFAULT nextval('public."PERSPECTIVE_FIELD_ID_seq"'::regclass);


--
-- Name: PREFERENCE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PREFERENCE" ALTER COLUMN "ID" SET DEFAULT nextval('public."PREFERENCE_ID_seq"'::regclass);


--
-- Name: PRODUCT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT" ALTER COLUMN "ID" SET DEFAULT nextval('public."PRODUCT_ID_seq"'::regclass);


--
-- Name: PRODUCT_KEY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY" ALTER COLUMN "ID" SET DEFAULT nextval('public."PRODUCT_KEY_ID_seq"'::regclass);


--
-- Name: RELEASE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RELEASE" ALTER COLUMN "ID" SET DEFAULT nextval('public."RELEASE_ID_seq"'::regclass);


--
-- Name: REMOTE_KEY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REMOTE_KEY" ALTER COLUMN "ID" SET DEFAULT nextval('public."REMOTE_KEY_ID_seq"'::regclass);


--
-- Name: REPORT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT" ALTER COLUMN "ID" SET DEFAULT nextval('public."REPORT_ID_seq"'::regclass);


--
-- Name: REPORT_RUN ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN" ALTER COLUMN "ID" SET DEFAULT nextval('public."REPORT_RUN_ID_seq"'::regclass);


--
-- Name: ROLE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROLE" ALTER COLUMN "ID" SET DEFAULT nextval('public."ROLE_ID_seq"'::regclass);


--
-- Name: SDPE_AVAILABLE_MODES ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SDPE_AVAILABLE_MODES" ALTER COLUMN "ID" SET DEFAULT nextval('public."SDPE_AVAILABLE_MODES_ID_seq"'::regclass);


--
-- Name: SEARCH_INDEX ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SEARCH_INDEX" ALTER COLUMN "ID" SET DEFAULT nextval('public."SEARCH_INDEX_ID_seq"'::regclass);


--
-- Name: TARGET ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET" ALTER COLUMN "ID" SET DEFAULT nextval('public."TARGET_ID_seq"'::regclass);


--
-- Name: TARGET_GROUP ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_GROUP" ALTER COLUMN "ID" SET DEFAULT nextval('public."TARGET_GROUP_ID_seq"'::regclass);


--
-- Name: USER ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER" ALTER COLUMN "ID" SET DEFAULT nextval('public."USER_ID_seq"'::regclass);


--
-- Name: USER_SESSION ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION" ALTER COLUMN "ID" SET DEFAULT nextval('public."USER_SESSION_ID_seq"'::regclass);


--
-- Name: USER_WATERMARK_MONITOR ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_WATERMARK_MONITOR" ALTER COLUMN "ID" SET DEFAULT nextval('public."USER_WATERMARK_MONITOR_ID_seq"'::regclass);


--
-- Name: VIEW ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW" ALTER COLUMN "ID" SET DEFAULT nextval('public."VIEW_ID_seq"'::regclass);


--
-- Name: VIEWPORT ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT" ALTER COLUMN "ID" SET DEFAULT nextval('public."VIEWPORT_ID_seq"'::regclass);


--
-- Name: VIEW_PROPERTY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW_PROPERTY" ALTER COLUMN "ID" SET DEFAULT nextval('public."VIEW_PROPERTY_ID_seq"'::regclass);


--
-- Name: VIRTUAL_DIRECTORY ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY" ALTER COLUMN "ID" SET DEFAULT nextval('public."VIRTUAL_DIRECTORY_ID_seq"'::regclass);


--
-- Name: VISUAL_WORKFLOW_JOB ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB" ALTER COLUMN "ID" SET DEFAULT nextval('public."VISUAL_WORKFLOW_JOB_ID_seq"'::regclass);


--
-- Name: VISUAL_WORKFLOW_JOB_RUN ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN" ALTER COLUMN "ID" SET DEFAULT nextval('public."VISUAL_WORKFLOW_JOB_RUN_ID_seq"'::regclass);


--
-- Name: VISUAL_WORKFLOW_NODE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE" ALTER COLUMN "ID" SET DEFAULT nextval('public."VISUAL_WORKFLOW_NODE_ID_seq"'::regclass);


--
-- Name: VISUAL_WORKFLOW_SOCKET ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET" ALTER COLUMN "ID" SET DEFAULT nextval('public."VISUAL_WORKFLOW_SOCKET_ID_seq"'::regclass);


--
-- Name: WORKSPACE ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE" ALTER COLUMN "ID" SET DEFAULT nextval('public."WORKSPACE_ID_seq"'::regclass);


--
-- Data for Name: ACTIVATION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ACTIVATION" ("ID", "HOSTNAME", "LAST_USED", "CHECKED_OUT", "ACTIVE_UNTIL", "ACTIVATED_USING_GRACE_PERIOD", "TIMEOUT", "ACTIVE_UNTIL_ACTIVATION_SERVER", "HARDWARE_ID", "IP_ADDRESS", "LICENSE_KEY", "PRODUCT_KEY", "LICENSE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: ACTIVATION_HISTORY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ACTIVATION_HISTORY" ("ID", "HOSTNAME", "IP_ADDRESS", "LICENSE_KEY", "ACTIVATED_DATE", "RELEASED_DATE", "LICENSE", "PRODUCT_KEY") FROM stdin;
\.


--
-- Data for Name: ACTIVATION_SERVER_DATA; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ACTIVATION_SERVER_DATA" ("ID", "LAST_ONLINE") FROM stdin;
1	2026-03-12 14:40:01.444
\.


--
-- Data for Name: ADVANCED_SEARCH; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ADVANCED_SEARCH" ("ID", "ALL_USERS", "CREATED", "MODIFIED", "NAME", "QUERY", "VIEW", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: APP; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."APP" ("ID", "APP_ID", "COMPATIBILITY", "DESCRIPTION", "ICON", "NAME", "STATUS", "VENDOR", "VERSION", "WEBSITE") FROM stdin;
\.


--
-- Data for Name: ATTRIBUTE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ATTRIBUTE" ("ID", "ACTIVE", "CHOICE_ORDER", "CONFIG", "CREATED", "DEFAULT_VALUE", "DESCRIPTION", "EMPTY_CELL_COLOR", "EXCLUDE_INACTIVE", "FREE_ADD", "INCLUDED_ROLES", "KEY_NAME", "MAPPABLE", "MAXIMUM", "MINIMUM", "MODIFIED", "NAME", "POPULATED_CELL_BACK_COLOR", "POPULATED_CELL_FORE_COLOR", "STATIC_ATTRIBUTE", "TYPE_EXTENSION_ID", "TYPE_ID", "VERSION_ID", "CHOICE_LIST", "CREATED_BY", "ENTITY", "MODIFIED_BY") FROM stdin;
1	t	\N	\N	2026-03-12 14:28:28.497	\N	Name of the product instance.	\N	f	f	\N	name	f	255	\N	2026-03-12 14:28:28.497	Name	\N	\N	t	com.rossvideo.common.rwp.metadata.base	SINGLE_LINE_STRING	1	\N	2	2	2
2	t	\N	\N	2026-03-12 14:28:28.509	\N	Product name of the product instance.	\N	f	f	\N	productName	f	255	\N	2026-03-12 14:28:28.509	Product Name	\N	\N	t	com.rossvideo.common.rwp.metadata.base	SINGLE_LINE_STRING	1	\N	2	2	2
3	t	\N	\N	2026-03-12 14:28:28.518	\N	Version of the product instance.	\N	f	f	\N	version	f	255	\N	2026-03-12 14:28:28.518	Version	\N	\N	t	com.rossvideo.common.rwp.metadata.base	SINGLE_LINE_STRING	1	\N	2	2	2
4	t	\N	\N	2026-03-12 14:28:28.56	\N	Name of the target.	\N	f	f	\N	name	f	255	\N	2026-03-12 14:28:28.56	Name	\N	\N	t	com.rossvideo.common.rwp.metadata.base	SINGLE_LINE_STRING	1	\N	2	1	2
5	t	\N	\N	2026-03-12 14:28:28.568	\N	Type of the target.	\N	f	f	\N	type	f	255	\N	2026-03-12 14:28:28.568	Type	\N	\N	t	com.rossvideo.common.rwp.metadata.base	SINGLE_LINE_STRING	1	\N	2	1	2
\.


--
-- Data for Name: ATTRIBUTE_PARAMETER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ATTRIBUTE_PARAMETER" ("ID", "CREATED", "CUSTOM", "FORMAT", "MODIFIED", "VERSION_ID", "ATTRIBUTE", "ATTRIBUTE_PARAMETER_SET", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: ATTRIBUTE_PARAMETER_SET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ATTRIBUTE_PARAMETER_SET" ("ID", "CREATED", "CUSTOM", "DESCRIPTION", "KEY_NAME", "MODIFIED", "NAME", "ROOT_DIRECTORY_TYPE_EXTENSION_ID", "ROOT_DIRECTORY_TYPE_ID", "SOURCE_ENTITY_DEFAULT", "VERSION_ID", "CREATED_BY", "INHERIT_FROM", "MODIFIED_BY", "SOURCE_ENTITY", "VIRTUAL_DIRECTORY") FROM stdin;
\.


--
-- Data for Name: BUNDLE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."BUNDLE" ("ID", "NAME", "VERSION") FROM stdin;
1	com.rossvideo.common.quartz	29.9.1.202602111506
2	com.rossvideo.constellation.ogp.adapter	3.13.0.202603111153
3	com.rossvideo.common.event	29.9.1.202602111506
4	com.rossvideo.constellation.syncthing.linux	3.13.0.202603111153
5	com.rossvideo.swing	1.1.0.202603051412
6	com.rossvideo.constellation.licensing.offline	3.13.0.202603111153
7	com.rossvideo.common.micrometer	29.9.1.202602111506
8	com.rossvideo.common.rwp.metadata.ogp	29.9.1.202602111506
9	com.rossvideo.constellation.notification.recipient	3.13.0.202603111153
10	com.rossvideo.common.flexjson	29.9.1.202602111506
11	com.rossvideo.common.lnf	4.4.0.202603051412
12	com.rossvideo.common.mariadb	29.9.1.202602111506
13	com.rossvideo.common.httputils	29.9.1.202602111506
14	com.rossvideo.constellation.licensing	3.13.0.202603111153
15	com.rossvideo.common.rwp.searchindex	29.9.1.202602111506
16	com.rossvideo.urm.core	1.0.0.202603051412
17	com.rossvideo.common.horizon	29.9.1.202602111506
18	com.rossvideo.common.constellation.visualworkflow	3.13.0.202603111153
19	com.rossvideo.constellation.ogp.hibernate	3.13.0.202603111153
20	com.rossvideo.constellation.visualworkflow	3.13.0.202603111153
21	com.rossvideo.common.connection	4.2.0.202603051412
22	com.rossvideo.common.oglml	2.2.0.202603051412
23	com.rossvideo.common.rwp.node	29.9.1.202602111506
24	com.rossvideo.common.serialization	29.9.1.202602111506
25	com.rossvideo.constellation.custompanel.hibernate	3.13.0.202603111153
26	com.rossvideo.common.utils	29.9.1.202602111506
27	com.rossvideo.common.rwp	29.9.1.202602111506
28	com.rossvideo.common.rwp.systemmonitor	29.9.1.202602111506
29	com.rossvideo.common.rossfiles	1.0.1.202603051412
30	com.rossvideo.common.hibernate	29.9.1.202602111506
31	com.rossvideo.oauth	1.0.0.202603051429
32	com.rossvideo.common.rwp.licensing	29.9.1.202602111506
33	com.rossvideo.common.mos	29.9.1.202602111506
34	com.rossvideo.constellation.domain	3.13.0.202603111153
35	com.rossvideo.constellation	3.13.0.202603111153
36	com.rossvideo.common.mysql.galera.cluster	29.9.1.202602111506
37	com.rossvideo.common.rwp.vfs	29.9.1.202602111506
38	com.rossvideo.common.mysql	29.9.1.202602111506
39	com.rossvideo.keys.core	1.0.4.202511271236
40	com.rossvideo.common.rwp.metadata	29.9.1.202602111506
41	com.rossvideo.constellation.orchestration	3.13.0.202603111153
42	com.rossvideo.common.rwp.search	29.9.1.202602111506
43	com.rossvideo.common.rwp.saml	29.9.1.202602111506
44	com.rossvideo.constellation.custompanel.adapter	3.13.0.202603111153
45	com.rossvideo.constellation.urm	3.13.0.202603111153
46	com.rossvideo.gear	5.0.0.202603051426
47	com.rossvideo.constellation.syncthing	3.13.0.202603111153
48	com.rossvideo.common.rwp.horizon	29.9.1.202602111506
49	com.rossvideo.common.service.win32.x86_64	29.9.1.202602111506
50	com.rossvideo.common.jetty.customizer	29.9.1.202602111506
51	com.rossvideo.common.service.linux.x86_64	29.9.1.202602111506
52	com.rossvideo.common.elasticsearch.client	29.9.1.202602111506
53	com.rossvideo.constellation.logging	3.13.0.202603111153
54	com.rossvideo.common.service	29.9.1.202602111506
55	com.rossvideo.common.rwp.logging	29.9.1.202602111506
56	com.rossvideo.common.rwp.perspective	29.9.1.202602111506
57	com.rossvideo.common.jackson	3.13.0.202603111153
58	com.rossvideo.gear.catena	1.0.0.202603051429
59	com.rossvideo.constellation.inventory	3.13.0.202603111153
60	com.rossvideo.common.mariadb.galera.cluster	29.9.1.202602111506
61	com.rossvideo.common.util	1.0.0.202603051412
62	com.rossvideo.common.rwp.ldap	29.9.1.202602111506
63	com.rossvideo.constellation.custompanel	3.13.0.202603111153
64	com.rossvideo.constellation.notification	3.13.0.202603111153
65	com.rossvideo.common.mediainfo	29.9.1.202602111506
66	com.rossvideo.common.rwp.users	29.9.1.202602111506
67	com.rossvideo.common.postgresql	29.9.1.202602111506
68	com.rossvideo.common.struts2	29.9.1.202602111506
69	com.rossvideo.common.websocket	29.9.1.202602111506
70	com.rossvideo.constellation.ogp	3.13.0.202603111153
71	com.rossvideo.common.rwp.database	29.9.1.202602111506
\.


--
-- Data for Name: C3P0; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."C3P0" (a) FROM stdin;
\.


--
-- Data for Name: CHOICE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CHOICE" ("ID", "ACTIVE", "BACKGROUND_COLOR", "CREATED", "FOREGROUND_COLOR", "MODIFIED", "NAME", "VALUE", "VERSION_ID", "CHOICE_LIST", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: CHOICE_LIST; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CHOICE_LIST" ("ID", "CREATED", "DESCRIPTION", "MODIFIED", "NAME", "TYPE_EXTENSION_ID", "TYPE_ID", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: CLOUD_TARGET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CLOUD_TARGET" ("ID", "INSTANCE_ID", "USE_PUBLIC_IP", "INSTANCE_STATE", "CLOUD_PROVIDER_TYPE_ID", "CLOUD_PROVIDER_TYPE_EXTENSION_ID") FROM stdin;
\.


--
-- Data for Name: COMPONENT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."COMPONENT" ("ID", "VERSION_ID", "RELEASE", "NAME", "INSTALLER_NAME", "DEFAULT_PATH", "INSTALLER_ARGS", "MD5HASH", "TAG", "CONFIGURATION", "PRODUCT_INSTALLER_ID", "PRODUCT_PASSWORD", "STARTUP_PROCESS", "SNAPSHOTS_ENABLED", "VALID_TARGET_PLATFORMS", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: COMPONENT_PROCESS; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."COMPONENT_PROCESS" ("ID", "NAME", "TYPE", "SERVICE_NAME", "IS_SERVICE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY", "COMPONENT", "INDEX") FROM stdin;
\.


--
-- Data for Name: CONFIGURATION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CONFIGURATION" ("ID", "BUNDLE", "CREATED", "MODIFIED", "NAME", "VALUE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	com.rossvideo.common.rwp	2026-03-12 14:29:51.318	2026-03-12 14:29:51.318	system.time.firstDayOfWeek	7	0	1	1
\.


--
-- Data for Name: CONFIGURATION_SNAPSHOT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CONFIGURATION_SNAPSHOT" ("ID", "NAME", "DESCRIPTION", "PARENT", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY", "TYPE") FROM stdin;
\.


--
-- Data for Name: CONFIGURATION_SNAPSHOT_HISTORY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CONFIGURATION_SNAPSHOT_HISTORY" ("ID", "TARGET_ID", "SOURCE_TARGET_ID", "CONFIGURATION_SNAPSHOT_ID", "COMPONENT_ID", "CREATED", "CREATED_BY") FROM stdin;
\.


--
-- Data for Name: CUSTOM_PANEL_FILE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CUSTOM_PANEL_FILE" ("ID", "CUSTOM_PANEL_NAMESPACE_ID", "FILE_VERSION", "UPLOADED_BY_ID", "UPLOADED_BY_DISPLAY_NAME", "PUBLISHED_BY_ID", "PUBLISHED_BY_DISPLAY_NAME", "UPLOAD_TIME", "PUBLISHED", "CUSTOM_PANEL_VERSION", "NOTES") FROM stdin;
\.


--
-- Data for Name: CUSTOM_PANEL_NAMESPACE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CUSTOM_PANEL_NAMESPACE" ("ID", "NAME", "PARENT_ID", "PUBLIC_ACCESS") FROM stdin;
\.


--
-- Data for Name: DEPLOYMENT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DEPLOYMENT" ("ID", "NAME", "LOCK", "RELEASE", "PARENT", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: DEPLOYMENT_COMPONENT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DEPLOYMENT_COMPONENT" ("ID", "VERSION_ID", "TARGET", "COMPONENT", "STATE", "STATE_REASON", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY", "DEPLOYMENT", "INDEX") FROM stdin;
\.


--
-- Data for Name: DEPLOYMENT_CONFIGURATION_SNAPSHOT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DEPLOYMENT_CONFIGURATION_SNAPSHOT" ("ID", "DEPLOYMENT_ID") FROM stdin;
\.


--
-- Data for Name: DISK_USAGE_MONITOR; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DISK_USAGE_MONITOR" ("BYTE_TYPE", "DRIVE_LETTER", "THRESHOLD", "ID") FROM stdin;
\.


--
-- Data for Name: DISPLAY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DISPLAY" ("ID", "CONFIG", "CREATED", "MODIFIED", "NAME", "TYPE_EXTENSION_ID", "TYPE_ID", "VERSION_ID", "CREATED_BY", "MANAGER", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: DISPLAY_ATTRIBUTE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DISPLAY_ATTRIBUTE" ("DISPLAY", "ATTRIBUTE") FROM stdin;
\.


--
-- Data for Name: ENTITY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY" ("ID", "CREATED", "GLOBALLY_SEARCHABLE", "ICON", "INTERNAL", "MODIFIED", "NAME", "REPORTABLE", "STATIC_ENTITY", "TABLE", "USER_CONFIGURABLE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "TITLE_ATTRIBUTE") FROM stdin;
1	2026-03-12 14:28:28.463	\N	/resources/constellation.orchestration/images/icons/view/target-icon.png	f	2026-03-12 14:28:28.463	Target	f	t	Target.CustomColumnPersister	t	0	\N	\N	\N
2	2026-03-12 14:28:28.474	\N	/resources/constellation.orchestration/images/icons/view/deployment.png	f	2026-03-12 14:28:28.474	Deployment	f	t	Deployment.CustomColumnPersister	t	0	\N	\N	\N
\.


--
-- Data for Name: ENTITY_CONNECTION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_CONNECTION" ("ID", "CREATED", "EDIT_FORM_DISPLAY_MODE", "MODIFIED", "NAME", "VERSION_ID", "CREATE_FORM", "CREATED_BY", "EDIT_FORM", "FROM_ENTITY", "MODIFIED_BY", "TO_ENTITY") FROM stdin;
\.


--
-- Data for Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING" ("ID", "CREATED", "MODIFIED", "CREATED_BY", "ENTITY_CONNECTION", "FROM_ENTITY_ATTRIBUTE", "MODIFIED_BY", "TO_ENTITY_ATTRIBUTE") FROM stdin;
\.


--
-- Data for Name: ENTITY_CONNECTION_INSTANCE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_CONNECTION_INSTANCE" ("ID", "CREATED", "FROM_INSTANCE", "MODIFIED", "TO_INSTANCE", "CREATED_BY", "ENTITY_CONNECTION", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: ENTITY_FORM; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_FORM" ("ID", "CREATED", "HIDDEN", "MODIFIED", "NAME", "REQUIRE_FORM", "VERSION_ID", "CREATED_BY", "ENTITY", "MODIFIED_BY") FROM stdin;
1	2026-03-12 14:28:28.548	f	2026-03-12 14:28:28.548	Default	\N	0	2	2	2
2	2026-03-12 14:28:28.59	f	2026-03-12 14:28:28.59	Default	\N	0	2	1	2
\.


--
-- Data for Name: ENTITY_FORM_ATTRIBUTE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_FORM_ATTRIBUTE" ("ID", "CREATED", "LABEL", "MODIFIED", "READ_ONLY", "REQUIRED", "VERSION_ID", "ATTRIBUTE", "CREATED_BY", "MODIFIED_BY", "ENTITY_FORM", "ORDER") FROM stdin;
1	2026-03-12 14:28:28.536	\N	2026-03-12 14:28:28.536	f	f	0	1	2	2	1	0
2	2026-03-12 14:28:28.542	\N	2026-03-12 14:28:28.542	t	f	0	2	2	2	1	1
3	2026-03-12 14:28:28.547	\N	2026-03-12 14:28:28.547	t	f	0	3	2	2	1	2
4	2026-03-12 14:28:28.584	\N	2026-03-12 14:28:28.584	f	f	0	4	2	2	2	0
5	2026-03-12 14:28:28.589	\N	2026-03-12 14:28:28.589	t	f	0	5	2	2	2	1
\.


--
-- Data for Name: ENTITY_INSTANCE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_INSTANCE" ("ID", "CREATED", "MODIFIED", "ORDER", "USER_ATTRIBUTES", "VERSION_ID", "CREATED_BY", "ENTITY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: ENTITY_MANAGER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ENTITY_MANAGER" ("ID", "CREATED", "EDIT_FORM_DISPLAY_MODE", "MODIFIED", "VERSION_ID", "CREATE_FORM", "CREATED_BY", "EDIT_FORM", "ENTITY", "MANAGER", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: FEATURE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."FEATURE" ("ID", "FULL_FEATURE_ID", "PRODUCT_FEATURE_ID", "NAME", "DESCRIPTION", "KEY", "MAINTENANCE", "PRODUCT", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: FEDERATED_SEARCH; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."FEDERATED_SEARCH" ("ID", "BY_USER", "CREATED", "CREATED_END", "CREATED_START", "DESCRIPTOR_ID", "LOCATIONS", "MISCELLANEOUS_END", "MISCELLANEOUS_START", "MODIFIED", "MODIFIED_END", "MODIFIED_START", "OPTIONS", "QUERY", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: FILE_SYSTEM; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."FILE_SYSTEM" ("ID", "CREATED", "CREDENTIALS", "MODIFIED", "NAME", "NAMESPACE", "PROVIDER", "ROOT", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	2026-03-12 14:28:28.495	\N	2026-03-12 14:28:28.495	Media	media	Local	/var/rossvideo/constellation/Media	0	2	2
2	2026-03-12 14:28:28.502	\N	2026-03-12 14:28:28.502	App Cache	appcache	Local	/var/rossvideo/constellation/Apps	0	2	2
\.


--
-- Data for Name: GATEWAY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."GATEWAY" ("ID", "CREATED", "HOST", "MODIFIED", "SECRET", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: HOST; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."HOST" ("ID", "HARDWARE_ID", "IP", "TYPE", "USER_NAME", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: HOTKEY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."HOTKEY" ("ID", "CREATED", "EXTENSION", "HOTKEY", "MODIFIED", "OBJECT", "ORDER", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: INTERNET_CONN_MONITOR; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."INTERNET_CONN_MONITOR" ("TIME_UNIT", "URL", "ID") FROM stdin;
\.


--
-- Data for Name: JOB; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."JOB" ("ID", "ALIAS", "BUNDLE", "CREATED", "MODIFIED", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	rwp.visualworkflow.BackgroundServices	com.rossvideo.common.constellation.visualworkflow	2026-03-12 14:28:28.47	2026-03-12 14:28:28.47	0	\N	\N
2	rwp.BackgroundServices	com.rossvideo.common.rwp	2026-03-12 14:28:28.478	2026-03-12 14:28:28.478	0	\N	\N
3	ldap.BackgroundServices	com.rossvideo.common.rwp.ldap	2026-03-12 14:28:28.481	2026-03-12 14:28:28.481	0	\N	\N
4	common.metadata.BackgroundServices	com.rossvideo.common.rwp.metadata	2026-03-12 14:28:28.483	2026-03-12 14:28:28.483	0	\N	\N
5	rpm.licenseAudit	com.rossvideo.constellation.licensing	2026-03-12 14:28:28.486	2026-03-12 14:28:28.486	0	\N	\N
6	rpm.logging.logRetention	com.rossvideo.constellation.logging	2026-03-12 14:28:28.491	2026-03-12 14:28:28.491	0	\N	\N
\.


--
-- Data for Name: JOB_NODE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."JOB_NODE" ("JOB", "NODE", "INDEX") FROM stdin;
1	1	0
2	1	0
3	1	0
4	1	0
5	1	0
6	1	0
\.


--
-- Data for Name: LICENSE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LICENSE" ("ID", "KEY", "REQUEST_CODE", "LICENSED_TO", "PURCHASED", "ACTIVATION_LIMIT", "ACTIVATED_OFFLINE", "NUMBER", "FEATURE", "PRODUCT_KEY", "MAINTENANCE_EXPIRY", "PURCHASE_DATE", "EXPIRY_DATE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: LICENSE_KEY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LICENSE_KEY" ("ID", "CREATED", "FEATURE_ID", "KEY", "LICENSED_TO", "MODIFIED", "REQUEST_CODE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "NODE") FROM stdin;
2	2026-03-12 14:28:29.486	210	\N	\N	2026-03-12 14:28:29.486	6-VDM70-KSZDR-HG92T	0	2	2	1
3	2026-03-12 14:28:29.492	220	\N	\N	2026-03-12 14:28:29.492	9-HTJ37-PN0NB-3CP3J	0	2	2	1
4	2026-03-12 14:28:29.496	240	\N	\N	2026-03-12 14:28:29.496	5-CBLPX-T0VJW-HM9CP	0	2	2	1
6	2026-03-12 14:28:29.502	1	3NKWW-91PNY-7E43V-3R7S0	Catena	2026-03-12 14:29:00.651	J-FPB23-3JT6B-WXC7C	1	2	1	1
15	2026-03-12 14:29:00.595	0	0N173-Q146H-93G7W	Catena	2026-03-12 14:29:00.595	\N	1	1	1	\N
7	2026-03-12 14:28:29.504	2	KK7VB-2F49W-6TLDG-L3K0X	Catena	2026-03-12 14:29:00.76	1-GKQQX-YWQYH-YNBB6	1	2	1	1
5	2026-03-12 14:28:29.499	200	CN1HS-9NBFZ-X7N4S-GSRLF	Catena	2026-03-12 14:29:00.811	F-J8LMT-15PHV-KHT1P	1	2	1	1
1	2026-03-12 14:28:29.477	290	ZRVW4-WVJKE-FVMWK-G392L	Catena	2026-03-12 14:29:00.958	7-GRZPE-QNQ67-MKN39	1	2	1	1
10	2026-03-12 14:28:29.509	300	NZFWP-W6HGE-EPRWW-HPYNX	Catena	2026-03-12 14:29:01.008	R-HZDQF-1M0RD-1VKFX	1	2	1	1
11	2026-03-12 14:28:29.51	310	2GD53-5SZNF-K1814-550RP	Catena	2026-03-12 14:29:01.059	1-YEGMJ-THE48-18K36	1	2	1	1
14	2026-03-12 14:28:29.517	421	GBVP0-G6XXY-PNN3Y-JLGX8	Catena	2026-03-12 14:29:01.112	H-N7B87-QWBNL-F3BFF	1	2	1	1
9	2026-03-12 14:28:29.507	422	V7YEK-TR9TN-ZYMKW-W1BZJ	Catena	2026-03-12 14:29:01.161	M-G5SQ6-1YWPN-MZZBP	1	2	1	1
8	2026-03-12 14:28:29.506	423	2XK33-5NYT9-0ST4G-N388Z	Catena	2026-03-12 14:29:01.209	0-HZN4D-2K8YB-5YE0S	1	2	1	1
13	2026-03-12 14:28:29.515	424	G3SWB-2YGPC-ZBMJX-CF36M	Catena	2026-03-12 14:29:01.257	P-GEDGH-81ETX-80F28	1	2	1	1
12	2026-03-12 14:28:29.513	425	XV47M-7CJJV-14FNW-6JV6Z	Catena	2026-03-12 14:29:01.309	7-SRDXD-2N7D6-MLY25	1	2	1	1
\.


--
-- Data for Name: MAIL_RECIPIENT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MAIL_RECIPIENT" ("ID", "EMAIL", "FULL_NAME", "SUBSCRIPTION_NOTIFICATIONS_ENABLED", "MAINTENANCE_NOTIFICATIONS_ENABLED", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: MAIL_SERVER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MAIL_SERVER" ("ID", "OUTGOING_HOST", "OUTGOING_PORT", "OUTGOING_ENCRYPTION", "OUTGOING_AUTHENTICATED", "OUTGOING_USERNAME", "OUTGOING_PASSWORD", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: MANAGER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MANAGER" ("ID", "CREATED", "ICON", "MODIFIED", "NAME", "SHOW_IN_WORKBENCH", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: MONITOR; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MONITOR" ("ID", "ALIAS", "BUNDLE", "CREATED", "ENABLED", "INTERVAL", "MODIFIED", "NAME", "TIME_TYPE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: NODE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."NODE" ("ID", "CREATED", "ENABLED", "HOST", "MODIFIED", "NAME", "ONLINE", "UNIQUE_ID", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	2026-03-12 14:28:28.453	t	192.168.1.16	2026-03-12 14:40:12.88	72b169293d8d	t	248142661	71	2	2
\.


--
-- Data for Name: NODE_STATUS; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."NODE_STATUS" ("ID", "CREATED", "MESSAGE", "MODIFIED", "ONLINE", "VERSION_ID", "CREATED_BY", "DESTINATION", "MODIFIED_BY", "SOURCE") FROM stdin;
\.


--
-- Data for Name: OGP_ATTRIBUTE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."OGP_ATTRIBUTE" ("OGP_KEY", "OGP_READ_ONLY", "OGP_TYPE", "OGP_WIDGET", "ID") FROM stdin;
\.


--
-- Data for Name: OGP_CHOICE_LIST; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."OGP_CHOICE_LIST" ("OGP_TYPE", "ID") FROM stdin;
\.


--
-- Data for Name: OGP_ENTITY_FORM; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."OGP_ENTITY_FORM" ("MENU_ID", "OGP_KEY", "ID", "OGP_MENU_GROUP") FROM stdin;
\.


--
-- Data for Name: OGP_FRAME; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."OGP_FRAME" ("ID", "NAME", "HOSTNAME", "PORT", "PROTOCOL", "USE_SSL", "CONNECTION_SETTINGS", "CREATED", "MODIFIED") FROM stdin;
2	NDI Source	10.62.152.123	7254	CATENA	f	<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">\n<properties>\n<comment>DashBoard Device Connection Settings</comment>\n<entry key="node-id">10.62.152.123:7254</entry>\n<entry key="access">full</entry>\n<entry key="address">10.62.152.123</entry>\n<entry key="port">7254</entry>\n<entry key="node-name">NDI Source</entry>\n<entry key="rememberConnection">true</entry>\n<entry key="connectionType">TCP</entry>\n<entry key="discoveryType">MANUAL</entry>\n<entry key="equipmentType">catena</entry>\n</properties>\n	2026-03-12 14:33:56.062	2026-03-12 14:33:56.219
\.


--
-- Data for Name: OGP_MENU_GROUP; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."OGP_MENU_GROUP" ("ID", "CREATED", "MODIFIED", "OGP_KEY", "OGP_MENU_ID", "OGP_NAME", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: PARAMETER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PARAMETER" ("ID", "CATEGORY", "CREATED", "CUSTOM", "DELIMETER", "FAMILY_GROUP_ZERO", "KEY", "MODIFIED", "NAMESPACE_URI", "ORDINAL", "PROVIDER", "VALUE", "VERSION_ID", "ATTRIBUTE_PARAMETER", "CREATED_BY", "MODIFIED_BY", "PARAMETER_SET") FROM stdin;
\.


--
-- Data for Name: PARAMETER_SET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PARAMETER_SET" ("ID", "CREATED", "CUSTOM", "DESCRIPTION", "KEY_NAME", "MODIFIED", "NAME", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: PERMISSION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PERMISSION" ("ID", "AUTHORIZED", "BUNDLE", "CREATED", "MODIFIED", "OBJECT", "PERMISSION", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "ROLE", "SCOPE") FROM stdin;
\.


--
-- Data for Name: PERSPECTIVE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PERSPECTIVE" ("ID", "BINDINGS", "CREATED", "MOBILE", "MODIFIED", "NAME", "SYSTEM_DEFAULT", "VERSION_ID", "WORKBENCH", "CREATED_BY", "MODIFIED_BY", "USER") FROM stdin;
\.


--
-- Data for Name: PERSPECTIVE_COLUMN; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PERSPECTIVE_COLUMN" ("ID", "COLUMN", "CREATED", "GRID", "MODIFIED", "ORDER", "VERSION_ID", "VIEW", "WIDTH", "CREATED_BY", "MODIFIED_BY", "PERSPECTIVE") FROM stdin;
\.


--
-- Data for Name: PERSPECTIVE_FIELD; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PERSPECTIVE_FIELD" ("ID", "CREATED", "FIELD", "MODIFIED", "ORDER", "VERSION_ID", "VIEW", "WIDTH", "CREATED_BY", "MODIFIED_BY", "PERSPECTIVE") FROM stdin;
\.


--
-- Data for Name: PREFERENCE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PREFERENCE" ("ID", "BUNDLE", "CREATED", "MODIFIED", "NAME", "VALUE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "USER") FROM stdin;
\.


--
-- Data for Name: PRODUCT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PRODUCT" ("ID", "PRODUCT_ID", "NAME", "ALIAS", "USE_FEATURE_LEVEL_MAINTENANCE", "LICENSING_MODE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: PRODUCT_KEY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PRODUCT_KEY" ("ID", "VERSION_ID", "KEY", "LICENCED_TO", "MAINTENANCE_EXPIRY_DATE", "CUSTOMER_DEPARTMENT", "CUSTOMER_ID", "LICENSED_SOFTWARE_VERSION", "ACTIVATED", "RUNNING_SOFTWARE_VERSION", "OFFLINE_REQUEST_CODE", "NOTES", "ACTIVATION_REQ_FILE_DUE_DATE", "DISABLED", "DEACTIVATION_REQUESTED", "CHECKED_OUT_HARDWARE_ID", "PRODUCT", "PARENT", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: PUBLIC_KEY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PUBLIC_KEY" ("NODE", "KEY", "IS_AUTHORIZED") FROM stdin;
\.


--
-- Data for Name: RELEASE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."RELEASE" ("ID", "PRODUCT", "STREAM", "VERSION", "KEY", "URL", "DEPLOYMENT_PACKAGE_URL", "SUMMARY", "RELEASE_DATE", "MAINTENANCE_DATE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: REMOTE_KEY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."REMOTE_KEY" ("ID", "KEY", "IV") FROM stdin;
\.


--
-- Data for Name: REPORT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."REPORT" ("ID", "CONFIGURATION", "CREATED", "DESCENDING", "DESCRIPTION", "FILTERS", "LIMIT", "MODIFIED", "NAME", "PURGE_DAY_LIMIT", "TEMPLATE", "TYPE_EXTENSION_ID", "TYPE_ID", "CREATED_BY", "ENTITY", "MODIFIED_BY", "ORDER_BY") FROM stdin;
\.


--
-- Data for Name: REPORT_RUN; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."REPORT_RUN" ("ID", "CREATED", "DATA", "END", "MESSAGE", "MODIFIED", "REPORT_VERSION", "START", "STATUS", "TIME_ZONE", "ACTIVE_NODE", "CREATED_BY", "MODIFIED_BY", "REPORT") FROM stdin;
\.


--
-- Data for Name: ROLE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ROLE" ("ID", "ACTIVE", "ADMINISTRATIVE", "CREATED", "DOMAIN", "MODIFIED", "NAME", "REMOTELY_ASSIGNABLE", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	t	t	2026-03-12 14:28:28.446	Local	2026-03-12 14:28:28.446	Local Administrators	\N	0	\N	\N
2	t	f	2026-03-12 14:28:28.477	Local	2026-03-12 14:28:28.477	DashBoard Default Role	\N	0	\N	\N
\.


--
-- Data for Name: ROSS_PLATFORM_TARGET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ROSS_PLATFORM_TARGET" ("ID", "ROSS_PLATFORM", "LOCK") FROM stdin;
\.


--
-- Data for Name: SDPE_AVAILABLE_MODES; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SDPE_AVAILABLE_MODES" ("ID", "TARGET_ID", "MODE", "INDEX") FROM stdin;
\.


--
-- Data for Name: SEARCH_INDEX; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SEARCH_INDEX" ("ID", "NAME", "STATUS") FROM stdin;
1	com.rossvideo.common.rwp.metadata.model.choice.Choice	NOT_INDEXED
2	com.rossvideo.common.rwp.metadata.model.mapping.AttributeParameterSet	NOT_INDEXED
3	com.rossvideo.common.rwp.model.vfs.VirtualDirectory	NOT_INDEXED
4	com.rossvideo.common.rwp.metadata.model.entityinstance.EntityInstance	NOT_INDEXED
5	com.rossvideo.common.rwp.metadata.model.choicelist.ChoiceList	NOT_INDEXED
6	com.rossvideo.constellation.orchestration.model.TargetModel	NOT_INDEXED
\.


--
-- Data for Name: SYNCTHING_DEVICE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SYNCTHING_DEVICE" ("NODE_ID", "DEVICE_ID", "ENABLED", "CREATED", "MODIFIED") FROM stdin;
1	J52EANE-HHHBBX7-ZZ53GDW-PLVMXLE-LVYKQT2-S5A3P7T-XHFJC76-K3XMNAB	t	2026-03-12 14:28:29.462	2026-03-12 14:28:29.462
\.


--
-- Data for Name: TARGET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."TARGET" ("ID", "VERSION_ID", "NAME", "TYPE", "IS_KEY_BASED", "STATE", "STATE_REASON", "IS_DEPLOYMENT_CREATED", "OS_NAME", "HOST", "PORT", "PLATFORM", "PRODUCT_COPY_DESTINATION", "ANSIBLE_CONNECTION", "ANSIBLE_SHELL_TYPE", "REMOTE_KEY", "PARENT", "TARGET_GROUP", "USERNAME", "USER_TYPE", "USER_DOMAIN", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: TARGET_CONFIGURATION_SNAPSHOT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."TARGET_CONFIGURATION_SNAPSHOT" ("ID", "TARGET_ID") FROM stdin;
\.


--
-- Data for Name: TARGET_GROUP; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."TARGET_GROUP" ("ID", "NAME") FROM stdin;
\.


--
-- Data for Name: USER; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."USER" ("ID", "ACTIVE", "API_ENABLED", "API_KEY", "CREATED", "DELETED", "DEPARTMENT", "DOMAIN", "EMAIL", "FIRST_NAME", "LAST_NAME", "MOBILE", "MODIFIED", "ORIGIN_ID", "ORIGIN_LOCATOR", "PASSWORD", "PHONE", "SALT", "TITLE", "USERNAME", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	t	\N	\N	2026-03-12 14:28:28.477	\N	\N	Local	\N	Administrator	\N	\N	2026-03-12 14:28:28.477	\N		25df9737216704a7d1dd74d1bb7329f97d6694b08ba14f4851b9ccdc9a4a2785	\N	d37603f27c884c29	\N	root	0	\N	\N
2	f	\N	CkkFB025CAm41115GuTwo6ubiKCfZXYDX4HNxHWQBhTXfFhSqWJncnetRZWKaYn7	2026-03-12 14:28:28.488	\N	\N	Local	\N	System	\N	\N	2026-03-12 14:28:28.488	\N		e6d29bab3ed9bc93efa776791628031e6592240203e262bc14288a2c11df1be6	\N	66f7a9077a5853d7	\N	system	0	\N	\N
\.


--
-- Data for Name: USER_ROLE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."USER_ROLE" ("USER", "ROLE") FROM stdin;
1	1
2	1
\.


--
-- Data for Name: USER_SESSION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."USER_SESSION" ("ID", "AUTHENTICATOR", "CREATED", "IP_ADDRESS", "MODIFIED", "SESSION_ID", "SESSION_TOKEN", "SSO_ID", "USE_CONCURRENT_USER", "USER_ACTIVE", "USER_AGENT", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "NODE", "USER") FROM stdin;
1	com.rossvideo.common.rwp.Local	2026-03-12 14:28:37.913	172.17.7.25	2026-03-12 14:40:06.669	node01inx73obpgcd81plsdeu8je06x0	5AE5F694D9C5B8C4	9xifEP139wQVpVeSx22vzWLg3aEqitO4skJEuD8yBUpMT5hthgL3RkucWYnJEVgJ	f	2026-03-12 14:35:23.23	Chrome 145.0.0.0 - Windows 10	48	2	2	1	1
\.


--
-- Data for Name: USER_SESSION_SAML_SESSION_INDEX; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."USER_SESSION_SAML_SESSION_INDEX" ("USER_SESSION_ID", "SESSION_INDEX") FROM stdin;
\.


--
-- Data for Name: USER_WATERMARK_MONITOR; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."USER_WATERMARK_MONITOR" ("ID", "CREATED", "MODIFIED", "SESSION_COUNT", "USER_COUNT", "VERSION_ID", "CREATED_BY", "MODIFIED_BY") FROM stdin;
1	2026-03-12 14:29:01.338	2026-03-12 14:29:01.338	0	0	0	2	2
\.


--
-- Data for Name: VIEW; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VIEW" ("ID", "CREATED", "EXTENSION", "FOCUSED", "HANDLE", "INDEX", "MODIFIED", "URL", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "USER", "VIEWPORT") FROM stdin;
8	2026-03-12 14:32:59.88	constellation.ogp.DeviceTree	\N	DeviceTree	1773325979877	2026-03-12 14:32:59.88	/ogp/DeviceTree/View.do?nocache=1773325979733	0	1	1	1	2
9	2026-03-12 14:34:08.927	constellation.custompanel	\N	1567355718	1773326048915	2026-03-12 14:34:08.927	/rpm.custompanel/CustomPanelManager/Object/ReactPage.do?option=eyJuYW1lIjoiRGV2aWNlIChOREkgU291cmNlIC0gU2xvdCAwKSIsIm9iamVjdElkIjoiMTAuNjIuMTUyLjEyMzo3MjU0X19fbHRfX19icl9fX2d0X19fU2xvdCAwX19fbHRfX19icl9fX2d0X19fRGV2aWNlIiwic2xvdCI6MCwiZnJhbWVJZCI6Mn0=&nocache=1773326048411	0	1	1	1	1
\.


--
-- Data for Name: VIEWPORT; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VIEWPORT" ("ID", "CREATED", "HEIGHT", "MODIFIED", "VERSION_ID", "WIDTH", "CREATED_BY", "FOCUSED", "MODIFIED_BY", "USER", "WORKSPACE", "INDEX") FROM stdin;
1	2026-03-12 14:28:42.662	\N	2026-03-12 14:28:42.662	0	\N	1	\N	1	1	1	Top
2	2026-03-12 14:31:06.095	\N	2026-03-12 14:31:06.095	0	\N	1	\N	1	1	1	Left
\.


--
-- Data for Name: VIEW_PROPERTY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VIEW_PROPERTY" ("ID", "CREATED", "HANDLE", "MODIFIED", "NAME", "VALUE", "VERSION_ID", "VIEW", "WORKBENCH", "CREATED_BY", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: VIRTUAL_DIRECTORY; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VIRTUAL_DIRECTORY" ("ID", "CREATED", "MODIFIED", "NAME", "UNIQUE_NAME", "VERSION_ID", "CREATED_BY", "MODIFIED_BY", "PARENT") FROM stdin;
1	2026-03-12 14:28:28.447	2026-03-12 14:28:28.447	com.rossvideo.common.rwp.visualworkflow.Common	com.rossvideo.common.rwp.visualworkflow.common	0	\N	\N	\N
2	2026-03-12 14:28:28.47	2026-03-12 14:28:28.47	com.rossvideo.constellation.custompanel.CustomPanel	com.rossvideo.constellation.custompanel.custompanel	0	\N	\N	\N
3	2026-03-12 14:28:28.478	2026-03-12 14:28:28.478	com.rossvideo.constellation.inventory.model.product.Release	com.rossvideo.constellation.inventory.model.product.release	0	\N	\N	\N
4	2026-03-12 14:28:28.483	2026-03-12 14:28:28.483	com.rossvideo.constellation.licensing.model.ProductKey	com.rossvideo.constellation.licensing.model.productkey	0	\N	\N	\N
5	2026-03-12 14:28:28.489	2026-03-12 14:28:28.489	com.rossvideo.constellation.log.Log	com.rossvideo.constellation.log.log	0	\N	\N	\N
6	2026-03-12 14:28:28.492	2026-03-12 14:28:28.492	com.rossvideo.constellation.orchestration.model.deployment.Deployment	com.rossvideo.constellation.orchestration.model.deployment.deployment	0	2	2	\N
7	2026-03-12 14:28:28.501	2026-03-12 14:28:28.501	com.rossvideo.constellation.orchestration.model.Target	com.rossvideo.constellation.orchestration.model.target	0	2	2	\N
8	2026-03-12 14:28:28.502	2026-03-12 14:28:28.502	com.rossvideo.constellation.orchestration.model.ConfigurationSnapshot	com.rossvideo.constellation.orchestration.model.configurationsnapshot	0	2	2	\N
9	2026-03-12 14:28:28.504	2026-03-12 14:28:28.504	OGP.Devices	ogp.devices	0	2	2	\N
\.


--
-- Data for Name: VISUAL_WORKFLOW_JOB; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VISUAL_WORKFLOW_JOB" ("ID", "VERSION_ID", "NAME", "ICON", "DESCRIPTION", "ENABLED", "PRIORITY", "SCHEDULE_TYPE_ID", "SCHEDULE_TYPE_EXTENSION_ID", "PATTERN_TYPE_ID", "PATTERN_TYPE_EXTENSION_ID", "PARENT", "SCHEDULE", "TIME_ZONE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: VISUAL_WORKFLOW_JOB_RUN; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VISUAL_WORKFLOW_JOB_RUN" ("ID", "VERSION_ID", "SUBMITTED", "START", "END", "JOB", "NODE", "STATUS", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: VISUAL_WORKFLOW_NODE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VISUAL_WORKFLOW_NODE" ("ID", "VERSION_ID", "NAME", "UUID", "X_POSITION", "Y_POSITION", "NODE_TYPE_ID", "NODE_TYPE_EXTENSION_ID", "JOB", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: VISUAL_WORKFLOW_SOCKET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VISUAL_WORKFLOW_SOCKET" ("ID", "VERSION_ID", "NAME", "KEY_NAME", "UUID", "CONFIGURATION", "SOCKET_TYPE_ID", "SOCKET_TYPE_EXTENSION_ID", "NODE", "CREATED", "CREATED_BY", "MODIFIED", "MODIFIED_BY") FROM stdin;
\.


--
-- Data for Name: VISUAL_WORKFLOW_SOCKET_CONNECTION; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VISUAL_WORKFLOW_SOCKET_CONNECTION" ("SOURCE", "DESTINATION") FROM stdin;
\.


--
-- Data for Name: VMWARE_TARGET; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."VMWARE_TARGET" ("ID", "TEMPLATE_NAME", "VM_NAME", "INITIAL_STATE", "NETWORK", "WAIT_FOR_IP") FROM stdin;
\.


--
-- Data for Name: WORKSPACE; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."WORKSPACE" ("ID", "CREATED", "MOBILE", "MODIFIED", "VERSION_ID", "WORKBENCH", "CREATED_BY", "MODIFIED_BY", "PERSPECTIVE", "USER") FROM stdin;
1	2026-03-12 14:28:38.397	f	2026-03-12 14:31:06.099	2	rwp.Workbench	1	1	\N	1
\.


--
-- Name: ACTIVATION_HISTORY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ACTIVATION_HISTORY_ID_seq"', 1, false);


--
-- Name: ACTIVATION_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ACTIVATION_ID_seq"', 1, false);


--
-- Name: ACTIVATION_SERVER_DATA_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ACTIVATION_SERVER_DATA_ID_seq"', 1, true);


--
-- Name: ADVANCED_SEARCH_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ADVANCED_SEARCH_ID_seq"', 1, false);


--
-- Name: APP_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."APP_ID_seq"', 1, false);


--
-- Name: ATTRIBUTE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ATTRIBUTE_ID_seq"', 5, true);


--
-- Name: ATTRIBUTE_PARAMETER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ATTRIBUTE_PARAMETER_ID_seq"', 1, false);


--
-- Name: ATTRIBUTE_PARAMETER_SET_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ATTRIBUTE_PARAMETER_SET_ID_seq"', 1, false);


--
-- Name: BUNDLE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."BUNDLE_ID_seq"', 71, true);


--
-- Name: CHOICE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CHOICE_ID_seq"', 1, false);


--
-- Name: CHOICE_LIST_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CHOICE_LIST_ID_seq"', 1, false);


--
-- Name: COMPONENT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."COMPONENT_ID_seq"', 1, false);


--
-- Name: COMPONENT_PROCESS_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."COMPONENT_PROCESS_ID_seq"', 1, false);


--
-- Name: CONFIGURATION_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CONFIGURATION_ID_seq"', 1, true);


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CONFIGURATION_SNAPSHOT_HISTORY_ID_seq"', 1, false);


--
-- Name: CONFIGURATION_SNAPSHOT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CONFIGURATION_SNAPSHOT_ID_seq"', 1, false);


--
-- Name: CUSTOM_PANEL_FILE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."CUSTOM_PANEL_FILE_ID_seq"', 1, false);


--
-- Name: DEPLOYMENT_COMPONENT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."DEPLOYMENT_COMPONENT_ID_seq"', 1, false);


--
-- Name: DEPLOYMENT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."DEPLOYMENT_ID_seq"', 1, false);


--
-- Name: DISPLAY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."DISPLAY_ID_seq"', 1, false);


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING_ID_seq"', 1, false);


--
-- Name: ENTITY_CONNECTION_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_CONNECTION_ID_seq"', 1, false);


--
-- Name: ENTITY_CONNECTION_INSTANCE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_CONNECTION_INSTANCE_ID_seq"', 1, false);


--
-- Name: ENTITY_FORM_ATTRIBUTE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_FORM_ATTRIBUTE_ID_seq"', 5, true);


--
-- Name: ENTITY_FORM_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_FORM_ID_seq"', 2, true);


--
-- Name: ENTITY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_ID_seq"', 2, true);


--
-- Name: ENTITY_INSTANCE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_INSTANCE_ID_seq"', 1, false);


--
-- Name: ENTITY_MANAGER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ENTITY_MANAGER_ID_seq"', 1, false);


--
-- Name: FEATURE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."FEATURE_ID_seq"', 1, false);


--
-- Name: FEDERATED_SEARCH_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."FEDERATED_SEARCH_ID_seq"', 1, false);


--
-- Name: FILE_SYSTEM_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."FILE_SYSTEM_ID_seq"', 2, true);


--
-- Name: GATEWAY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."GATEWAY_ID_seq"', 1, false);


--
-- Name: HOST_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."HOST_ID_seq"', 1, false);


--
-- Name: HOTKEY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."HOTKEY_ID_seq"', 1, false);


--
-- Name: JOB_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."JOB_ID_seq"', 6, true);


--
-- Name: LICENSE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."LICENSE_ID_seq"', 1, false);


--
-- Name: LICENSE_KEY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."LICENSE_KEY_ID_seq"', 15, true);


--
-- Name: MAIL_RECIPIENT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."MAIL_RECIPIENT_ID_seq"', 1, false);


--
-- Name: MAIL_SERVER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."MAIL_SERVER_ID_seq"', 1, false);


--
-- Name: MANAGER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."MANAGER_ID_seq"', 1, false);


--
-- Name: MONITOR_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."MONITOR_ID_seq"', 1, false);


--
-- Name: NODE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."NODE_ID_seq"', 1, true);


--
-- Name: NODE_STATUS_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."NODE_STATUS_ID_seq"', 1, false);


--
-- Name: OGP_FRAME_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."OGP_FRAME_ID_seq"', 2, true);


--
-- Name: OGP_MENU_GROUP_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."OGP_MENU_GROUP_ID_seq"', 1, false);


--
-- Name: PARAMETER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PARAMETER_ID_seq"', 1, false);


--
-- Name: PARAMETER_SET_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PARAMETER_SET_ID_seq"', 1, false);


--
-- Name: PERMISSION_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PERMISSION_ID_seq"', 1, false);


--
-- Name: PERSPECTIVE_COLUMN_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PERSPECTIVE_COLUMN_ID_seq"', 1, false);


--
-- Name: PERSPECTIVE_FIELD_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PERSPECTIVE_FIELD_ID_seq"', 1, false);


--
-- Name: PERSPECTIVE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PERSPECTIVE_ID_seq"', 1, false);


--
-- Name: PREFERENCE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PREFERENCE_ID_seq"', 1, false);


--
-- Name: PRODUCT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PRODUCT_ID_seq"', 1, false);


--
-- Name: PRODUCT_KEY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."PRODUCT_KEY_ID_seq"', 1, false);


--
-- Name: RELEASE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."RELEASE_ID_seq"', 1, false);


--
-- Name: REMOTE_KEY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."REMOTE_KEY_ID_seq"', 1, false);


--
-- Name: REPORT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."REPORT_ID_seq"', 1, false);


--
-- Name: REPORT_RUN_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."REPORT_RUN_ID_seq"', 1, false);


--
-- Name: ROLE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ROLE_ID_seq"', 2, true);


--
-- Name: SDPE_AVAILABLE_MODES_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."SDPE_AVAILABLE_MODES_ID_seq"', 1, false);


--
-- Name: SEARCH_INDEX_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."SEARCH_INDEX_ID_seq"', 6, true);


--
-- Name: TARGET_GROUP_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."TARGET_GROUP_ID_seq"', 1, false);


--
-- Name: TARGET_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."TARGET_ID_seq"', 1, false);


--
-- Name: USER_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."USER_ID_seq"', 2, true);


--
-- Name: USER_SESSION_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."USER_SESSION_ID_seq"', 1, true);


--
-- Name: USER_WATERMARK_MONITOR_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."USER_WATERMARK_MONITOR_ID_seq"', 1, true);


--
-- Name: VIEWPORT_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VIEWPORT_ID_seq"', 2, true);


--
-- Name: VIEW_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VIEW_ID_seq"', 9, true);


--
-- Name: VIEW_PROPERTY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VIEW_PROPERTY_ID_seq"', 1, false);


--
-- Name: VIRTUAL_DIRECTORY_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VIRTUAL_DIRECTORY_ID_seq"', 9, true);


--
-- Name: VISUAL_WORKFLOW_JOB_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VISUAL_WORKFLOW_JOB_ID_seq"', 1, false);


--
-- Name: VISUAL_WORKFLOW_JOB_RUN_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VISUAL_WORKFLOW_JOB_RUN_ID_seq"', 1, false);


--
-- Name: VISUAL_WORKFLOW_NODE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VISUAL_WORKFLOW_NODE_ID_seq"', 1, false);


--
-- Name: VISUAL_WORKFLOW_SOCKET_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."VISUAL_WORKFLOW_SOCKET_ID_seq"', 1, false);


--
-- Name: WORKSPACE_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."WORKSPACE_ID_seq"', 1, true);


--
-- Name: ACTIVATION_HISTORY ACTIVATION_HISTORY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_HISTORY"
    ADD CONSTRAINT "ACTIVATION_HISTORY_pkey" PRIMARY KEY ("ID");


--
-- Name: ACTIVATION_SERVER_DATA ACTIVATION_SERVER_DATA_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_SERVER_DATA"
    ADD CONSTRAINT "ACTIVATION_SERVER_DATA_pkey" PRIMARY KEY ("ID");


--
-- Name: ACTIVATION ACTIVATION_UNIQUE_CONSTRAINT; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "ACTIVATION_UNIQUE_CONSTRAINT" UNIQUE ("HARDWARE_ID", "IP_ADDRESS", "LICENSE_KEY", "PRODUCT_KEY");


--
-- Name: ACTIVATION ACTIVATION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "ACTIVATION_pkey" PRIMARY KEY ("ID");


--
-- Name: ADVANCED_SEARCH ADVANCED_SEARCH_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ADVANCED_SEARCH"
    ADD CONSTRAINT "ADVANCED_SEARCH_pkey" PRIMARY KEY ("ID");


--
-- Name: APP APP_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."APP"
    ADD CONSTRAINT "APP_pkey" PRIMARY KEY ("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET ATTRIBUTE_PARAMETER_SET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "ATTRIBUTE_PARAMETER_SET_pkey" PRIMARY KEY ("ID");


--
-- Name: ATTRIBUTE_PARAMETER ATTRIBUTE_PARAMETER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER"
    ADD CONSTRAINT "ATTRIBUTE_PARAMETER_pkey" PRIMARY KEY ("ID");


--
-- Name: ATTRIBUTE ATTRIBUTE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE"
    ADD CONSTRAINT "ATTRIBUTE_pkey" PRIMARY KEY ("ID");


--
-- Name: BUNDLE BUNDLE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BUNDLE"
    ADD CONSTRAINT "BUNDLE_pkey" PRIMARY KEY ("ID");


--
-- Name: CHOICE_LIST CHOICE_LIST_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE_LIST"
    ADD CONSTRAINT "CHOICE_LIST_pkey" PRIMARY KEY ("ID");


--
-- Name: CHOICE CHOICE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE"
    ADD CONSTRAINT "CHOICE_pkey" PRIMARY KEY ("ID");


--
-- Name: CLOUD_TARGET CLOUD_TARGET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CLOUD_TARGET"
    ADD CONSTRAINT "CLOUD_TARGET_pkey" PRIMARY KEY ("ID");


--
-- Name: COMPONENT_PROCESS COMPONENT_PROCESS_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT_PROCESS"
    ADD CONSTRAINT "COMPONENT_PROCESS_pkey" PRIMARY KEY ("ID");


--
-- Name: COMPONENT COMPONENT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT"
    ADD CONSTRAINT "COMPONENT_pkey" PRIMARY KEY ("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY CONFIGURATION_SNAPSHOT_HISTORY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "CONFIGURATION_SNAPSHOT_HISTORY_pkey" PRIMARY KEY ("ID");


--
-- Name: CONFIGURATION_SNAPSHOT CONFIGURATION_SNAPSHOT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "CONFIGURATION_SNAPSHOT_pkey" PRIMARY KEY ("ID");


--
-- Name: CONFIGURATION CONFIGURATION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION"
    ADD CONSTRAINT "CONFIGURATION_pkey" PRIMARY KEY ("ID");


--
-- Name: CUSTOM_PANEL_FILE CUSTOM_PANEL_FILE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CUSTOM_PANEL_FILE"
    ADD CONSTRAINT "CUSTOM_PANEL_FILE_pkey" PRIMARY KEY ("ID");


--
-- Name: CUSTOM_PANEL_NAMESPACE CUSTOM_PANEL_NAMESPACE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CUSTOM_PANEL_NAMESPACE"
    ADD CONSTRAINT "CUSTOM_PANEL_NAMESPACE_pkey" PRIMARY KEY ("ID");


--
-- Name: DEPLOYMENT_COMPONENT DEPLOYMENT_COMPONENT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "DEPLOYMENT_COMPONENT_pkey" PRIMARY KEY ("ID");


--
-- Name: DEPLOYMENT_CONFIGURATION_SNAPSHOT DEPLOYMENT_CONFIGURATION_SNAPSHOT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "DEPLOYMENT_CONFIGURATION_SNAPSHOT_pkey" PRIMARY KEY ("ID");


--
-- Name: DEPLOYMENT DEPLOYMENT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT "DEPLOYMENT_pkey" PRIMARY KEY ("ID");


--
-- Name: DISK_USAGE_MONITOR DISK_USAGE_MONITOR_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISK_USAGE_MONITOR"
    ADD CONSTRAINT "DISK_USAGE_MONITOR_pkey" PRIMARY KEY ("ID");


--
-- Name: DISPLAY_ATTRIBUTE DISPLAY_ATTRIBUTE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY_ATTRIBUTE"
    ADD CONSTRAINT "DISPLAY_ATTRIBUTE_pkey" PRIMARY KEY ("DISPLAY", "ATTRIBUTE");


--
-- Name: DISPLAY DISPLAY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY"
    ADD CONSTRAINT "DISPLAY_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING ENTITY_CONNECTION_ATTRIBUTE_MAPPING_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "ENTITY_CONNECTION_ATTRIBUTE_MAPPING_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_CONNECTION_INSTANCE ENTITY_CONNECTION_INSTANCE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE"
    ADD CONSTRAINT "ENTITY_CONNECTION_INSTANCE_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_CONNECTION ENTITY_CONNECTION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "ENTITY_CONNECTION_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_FORM_ATTRIBUTE ENTITY_FORM_ATTRIBUTE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE"
    ADD CONSTRAINT "ENTITY_FORM_ATTRIBUTE_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_FORM ENTITY_FORM_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM"
    ADD CONSTRAINT "ENTITY_FORM_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_INSTANCE ENTITY_INSTANCE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_INSTANCE"
    ADD CONSTRAINT "ENTITY_INSTANCE_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY_MANAGER ENTITY_MANAGER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "ENTITY_MANAGER_pkey" PRIMARY KEY ("ID");


--
-- Name: ENTITY ENTITY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY"
    ADD CONSTRAINT "ENTITY_pkey" PRIMARY KEY ("ID");


--
-- Name: FEATURE FEATURE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE"
    ADD CONSTRAINT "FEATURE_pkey" PRIMARY KEY ("ID");


--
-- Name: FEDERATED_SEARCH FEDERATED_SEARCH_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEDERATED_SEARCH"
    ADD CONSTRAINT "FEDERATED_SEARCH_pkey" PRIMARY KEY ("ID");


--
-- Name: FILE_SYSTEM FILE_SYSTEM_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FILE_SYSTEM"
    ADD CONSTRAINT "FILE_SYSTEM_pkey" PRIMARY KEY ("ID");


--
-- Name: GATEWAY GATEWAY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GATEWAY"
    ADD CONSTRAINT "GATEWAY_pkey" PRIMARY KEY ("ID");


--
-- Name: HOST HOST_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOST"
    ADD CONSTRAINT "HOST_pkey" PRIMARY KEY ("ID");


--
-- Name: HOTKEY HOTKEY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOTKEY"
    ADD CONSTRAINT "HOTKEY_pkey" PRIMARY KEY ("ID");


--
-- Name: INTERNET_CONN_MONITOR INTERNET_CONN_MONITOR_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."INTERNET_CONN_MONITOR"
    ADD CONSTRAINT "INTERNET_CONN_MONITOR_pkey" PRIMARY KEY ("ID");


--
-- Name: JOB_NODE JOB_NODE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB_NODE"
    ADD CONSTRAINT "JOB_NODE_pkey" PRIMARY KEY ("JOB", "INDEX");


--
-- Name: JOB JOB_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB"
    ADD CONSTRAINT "JOB_pkey" PRIMARY KEY ("ID");


--
-- Name: LICENSE_KEY LICENSE_KEY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE_KEY"
    ADD CONSTRAINT "LICENSE_KEY_pkey" PRIMARY KEY ("ID");


--
-- Name: LICENSE LICENSE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE"
    ADD CONSTRAINT "LICENSE_pkey" PRIMARY KEY ("ID");


--
-- Name: MAIL_RECIPIENT MAIL_RECIPIENT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_RECIPIENT"
    ADD CONSTRAINT "MAIL_RECIPIENT_pkey" PRIMARY KEY ("ID");


--
-- Name: MAIL_SERVER MAIL_SERVER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_SERVER"
    ADD CONSTRAINT "MAIL_SERVER_pkey" PRIMARY KEY ("ID");


--
-- Name: MANAGER MANAGER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MANAGER"
    ADD CONSTRAINT "MANAGER_pkey" PRIMARY KEY ("ID");


--
-- Name: MONITOR MONITOR_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MONITOR"
    ADD CONSTRAINT "MONITOR_pkey" PRIMARY KEY ("ID");


--
-- Name: NODE_STATUS NODE_STATUS_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS"
    ADD CONSTRAINT "NODE_STATUS_pkey" PRIMARY KEY ("ID");


--
-- Name: NODE NODE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE"
    ADD CONSTRAINT "NODE_pkey" PRIMARY KEY ("ID");


--
-- Name: OGP_ATTRIBUTE OGP_ATTRIBUTE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_ATTRIBUTE"
    ADD CONSTRAINT "OGP_ATTRIBUTE_pkey" PRIMARY KEY ("ID");


--
-- Name: OGP_CHOICE_LIST OGP_CHOICE_LIST_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_CHOICE_LIST"
    ADD CONSTRAINT "OGP_CHOICE_LIST_pkey" PRIMARY KEY ("ID");


--
-- Name: OGP_ENTITY_FORM OGP_ENTITY_FORM_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_ENTITY_FORM"
    ADD CONSTRAINT "OGP_ENTITY_FORM_pkey" PRIMARY KEY ("ID");


--
-- Name: OGP_FRAME OGP_FRAME_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_FRAME"
    ADD CONSTRAINT "OGP_FRAME_pkey" PRIMARY KEY ("ID");


--
-- Name: OGP_MENU_GROUP OGP_MENU_GROUP_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_MENU_GROUP"
    ADD CONSTRAINT "OGP_MENU_GROUP_pkey" PRIMARY KEY ("ID");


--
-- Name: PARAMETER_SET PARAMETER_SET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER_SET"
    ADD CONSTRAINT "PARAMETER_SET_pkey" PRIMARY KEY ("ID");


--
-- Name: PARAMETER PARAMETER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER"
    ADD CONSTRAINT "PARAMETER_pkey" PRIMARY KEY ("ID");


--
-- Name: PERMISSION PERMISSION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION"
    ADD CONSTRAINT "PERMISSION_pkey" PRIMARY KEY ("ID");


--
-- Name: PERSPECTIVE_COLUMN PERSPECTIVE_COLUMN_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_COLUMN"
    ADD CONSTRAINT "PERSPECTIVE_COLUMN_pkey" PRIMARY KEY ("ID");


--
-- Name: PERSPECTIVE_FIELD PERSPECTIVE_FIELD_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_FIELD"
    ADD CONSTRAINT "PERSPECTIVE_FIELD_pkey" PRIMARY KEY ("ID");


--
-- Name: PERSPECTIVE PERSPECTIVE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE"
    ADD CONSTRAINT "PERSPECTIVE_pkey" PRIMARY KEY ("ID");


--
-- Name: PREFERENCE PREFERENCE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PREFERENCE"
    ADD CONSTRAINT "PREFERENCE_pkey" PRIMARY KEY ("ID");


--
-- Name: PRODUCT_KEY PRODUCT_KEY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT "PRODUCT_KEY_pkey" PRIMARY KEY ("ID");


--
-- Name: PRODUCT PRODUCT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT"
    ADD CONSTRAINT "PRODUCT_pkey" PRIMARY KEY ("ID");


--
-- Name: PUBLIC_KEY PUBLIC_KEY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PUBLIC_KEY"
    ADD CONSTRAINT "PUBLIC_KEY_pkey" PRIMARY KEY ("NODE");


--
-- Name: RELEASE RELEASE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RELEASE"
    ADD CONSTRAINT "RELEASE_pkey" PRIMARY KEY ("ID");


--
-- Name: REMOTE_KEY REMOTE_KEY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REMOTE_KEY"
    ADD CONSTRAINT "REMOTE_KEY_pkey" PRIMARY KEY ("ID");


--
-- Name: REPORT_RUN REPORT_RUN_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN"
    ADD CONSTRAINT "REPORT_RUN_pkey" PRIMARY KEY ("ID");


--
-- Name: REPORT REPORT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "REPORT_pkey" PRIMARY KEY ("ID");


--
-- Name: ROLE ROLE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROLE"
    ADD CONSTRAINT "ROLE_pkey" PRIMARY KEY ("ID");


--
-- Name: ROSS_PLATFORM_TARGET ROSS_PLATFORM_TARGET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROSS_PLATFORM_TARGET"
    ADD CONSTRAINT "ROSS_PLATFORM_TARGET_pkey" PRIMARY KEY ("ID");


--
-- Name: SDPE_AVAILABLE_MODES SDPE_AVAILABLE_MODES_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SDPE_AVAILABLE_MODES"
    ADD CONSTRAINT "SDPE_AVAILABLE_MODES_pkey" PRIMARY KEY ("ID");


--
-- Name: SEARCH_INDEX SEARCH_INDEX_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SEARCH_INDEX"
    ADD CONSTRAINT "SEARCH_INDEX_pkey" PRIMARY KEY ("ID");


--
-- Name: SYNCTHING_DEVICE SYNCTHING_DEVICE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SYNCTHING_DEVICE"
    ADD CONSTRAINT "SYNCTHING_DEVICE_pkey" PRIMARY KEY ("NODE_ID");


--
-- Name: TARGET_CONFIGURATION_SNAPSHOT TARGET_CONFIGURATION_SNAPSHOT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "TARGET_CONFIGURATION_SNAPSHOT_pkey" PRIMARY KEY ("ID");


--
-- Name: TARGET_GROUP TARGET_GROUP_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_GROUP"
    ADD CONSTRAINT "TARGET_GROUP_pkey" PRIMARY KEY ("ID");


--
-- Name: TARGET TARGET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "TARGET_pkey" PRIMARY KEY ("ID");


--
-- Name: CONFIGURATION UK_BUNDLE_NAME; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION"
    ADD CONSTRAINT "UK_BUNDLE_NAME" UNIQUE ("BUNDLE", "NAME");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING UK_ENTITY_CONNECTION_ATTRIBUTE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "UK_ENTITY_CONNECTION_ATTRIBUTE" UNIQUE ("FROM_ENTITY_ATTRIBUTE", "TO_ENTITY_ATTRIBUTE", "ENTITY_CONNECTION");


--
-- Name: ENTITY_CONNECTION UK_ENTITY_CONNECTION_FROM_TO; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "UK_ENTITY_CONNECTION_FROM_TO" UNIQUE ("FROM_ENTITY", "TO_ENTITY");


--
-- Name: ENTITY_CONNECTION_INSTANCE UK_ENTITY_CONN_INSTANCE_FROM_TO_CONN; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE"
    ADD CONSTRAINT "UK_ENTITY_CONN_INSTANCE_FROM_TO_CONN" UNIQUE ("FROM_INSTANCE", "TO_INSTANCE", "ENTITY_CONNECTION");


--
-- Name: ENTITY_MANAGER UK_ENTITY_MANAGER_ASSOCIATION; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "UK_ENTITY_MANAGER_ASSOCIATION" UNIQUE ("ENTITY", "MANAGER");


--
-- Name: FILE_SYSTEM UK_FILE_SYSTEM_NAMESPACE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FILE_SYSTEM"
    ADD CONSTRAINT "UK_FILE_SYSTEM_NAMESPACE" UNIQUE ("NAMESPACE");


--
-- Name: NODE UK_HOST; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE"
    ADD CONSTRAINT "UK_HOST" UNIQUE ("HOST");


--
-- Name: MANAGER UK_MANAGER_NAME; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MANAGER"
    ADD CONSTRAINT "UK_MANAGER_NAME" UNIQUE ("NAME");


--
-- Name: NODE UK_NODE_UNIQUE_ID; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE"
    ADD CONSTRAINT "UK_NODE_UNIQUE_ID" UNIQUE ("UNIQUE_ID");


--
-- Name: REPORT UK_REPORT_NAME; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "UK_REPORT_NAME" UNIQUE ("NAME");


--
-- Name: SYNCTHING_DEVICE UK_SYNCTHING_DEVICE_DEVICE_ID; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SYNCTHING_DEVICE"
    ADD CONSTRAINT "UK_SYNCTHING_DEVICE_DEVICE_ID" UNIQUE ("DEVICE_ID");


--
-- Name: DISPLAY UK_TYPE_MANAGER_ASSOCIATION; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY"
    ADD CONSTRAINT "UK_TYPE_MANAGER_ASSOCIATION" UNIQUE ("TYPE_ID", "TYPE_EXTENSION_ID", "MANAGER");


--
-- Name: USER UK_USER_DOMAIN_USERNAME; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER"
    ADD CONSTRAINT "UK_USER_DOMAIN_USERNAME" UNIQUE ("DOMAIN", "USERNAME");


--
-- Name: USER_SESSION UK_USER_SESSION_SESSION_ID; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "UK_USER_SESSION_SESSION_ID" UNIQUE ("SESSION_ID");


--
-- Name: VIRTUAL_DIRECTORY UK_VIRTUAL_DIRECTORY_NAMESPACE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY"
    ADD CONSTRAINT "UK_VIRTUAL_DIRECTORY_NAMESPACE" UNIQUE ("UNIQUE_NAME", "PARENT");


--
-- Name: VISUAL_WORKFLOW_JOB UK_VISUAL_WORKFLOW_JOB_NAME; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB"
    ADD CONSTRAINT "UK_VISUAL_WORKFLOW_JOB_NAME" UNIQUE ("NAME");


--
-- Name: USER_ROLE USER_ROLE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_ROLE"
    ADD CONSTRAINT "USER_ROLE_pkey" PRIMARY KEY ("USER", "ROLE");


--
-- Name: USER_SESSION_SAML_SESSION_INDEX USER_SESSION_SAML_SESSION_INDEX_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION_SAML_SESSION_INDEX"
    ADD CONSTRAINT "USER_SESSION_SAML_SESSION_INDEX_pkey" PRIMARY KEY ("USER_SESSION_ID");


--
-- Name: USER_SESSION USER_SESSION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "USER_SESSION_pkey" PRIMARY KEY ("ID");


--
-- Name: USER_WATERMARK_MONITOR USER_WATERMARK_MONITOR_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_WATERMARK_MONITOR"
    ADD CONSTRAINT "USER_WATERMARK_MONITOR_pkey" PRIMARY KEY ("ID");


--
-- Name: USER USER_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER"
    ADD CONSTRAINT "USER_pkey" PRIMARY KEY ("ID");


--
-- Name: VIEWPORT VIEWPORT_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "VIEWPORT_pkey" PRIMARY KEY ("ID");


--
-- Name: VIEW_PROPERTY VIEW_PROPERTY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW_PROPERTY"
    ADD CONSTRAINT "VIEW_PROPERTY_pkey" PRIMARY KEY ("ID");


--
-- Name: VIEW VIEW_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW"
    ADD CONSTRAINT "VIEW_pkey" PRIMARY KEY ("ID");


--
-- Name: VIRTUAL_DIRECTORY VIRTUAL_DIRECTORY_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY"
    ADD CONSTRAINT "VIRTUAL_DIRECTORY_pkey" PRIMARY KEY ("ID");


--
-- Name: VISUAL_WORKFLOW_JOB_RUN VISUAL_WORKFLOW_JOB_RUN_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN"
    ADD CONSTRAINT "VISUAL_WORKFLOW_JOB_RUN_pkey" PRIMARY KEY ("ID");


--
-- Name: VISUAL_WORKFLOW_JOB VISUAL_WORKFLOW_JOB_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB"
    ADD CONSTRAINT "VISUAL_WORKFLOW_JOB_pkey" PRIMARY KEY ("ID");


--
-- Name: VISUAL_WORKFLOW_NODE VISUAL_WORKFLOW_NODE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE"
    ADD CONSTRAINT "VISUAL_WORKFLOW_NODE_pkey" PRIMARY KEY ("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET_CONNECTION VISUAL_WORKFLOW_SOCKET_CONNECTION_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET_CONNECTION"
    ADD CONSTRAINT "VISUAL_WORKFLOW_SOCKET_CONNECTION_pkey" PRIMARY KEY ("SOURCE", "DESTINATION");


--
-- Name: VISUAL_WORKFLOW_SOCKET VISUAL_WORKFLOW_SOCKET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET"
    ADD CONSTRAINT "VISUAL_WORKFLOW_SOCKET_pkey" PRIMARY KEY ("ID");


--
-- Name: VMWARE_TARGET VMWARE_TARGET_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VMWARE_TARGET"
    ADD CONSTRAINT "VMWARE_TARGET_pkey" PRIMARY KEY ("ID");


--
-- Name: WORKSPACE WORKSPACE_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE"
    ADD CONSTRAINT "WORKSPACE_pkey" PRIMARY KEY ("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET uk_8tkcrjurjpq67k8e8tcbau9vq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET"
    ADD CONSTRAINT uk_8tkcrjurjpq67k8e8tcbau9vq UNIQUE ("UUID");


--
-- Name: VISUAL_WORKFLOW_NODE uk_9b26umfnfxlfrftxo2w3v0wih; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE"
    ADD CONSTRAINT uk_9b26umfnfxlfrftxo2w3v0wih UNIQUE ("UUID");


--
-- Name: DEPLOYMENT uk_b0xb2e6fp15o9y0hm7q92biq1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT uk_b0xb2e6fp15o9y0hm7q92biq1 UNIQUE ("NAME");


--
-- Name: PRODUCT_KEY uk_cq0rks53hdlef1n2ffx53la49; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT uk_cq0rks53hdlef1n2ffx53la49 UNIQUE ("KEY");


--
-- Name: FEATURE uk_cqp0mmmt7ii0hwhellwo9pwl0; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE"
    ADD CONSTRAINT uk_cqp0mmmt7ii0hwhellwo9pwl0 UNIQUE ("FULL_FEATURE_ID");


--
-- Name: PRODUCT uk_hqwmmht0gcdpnlrpbg7do7ir7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT"
    ADD CONSTRAINT uk_hqwmmht0gcdpnlrpbg7do7ir7 UNIQUE ("PRODUCT_ID");


--
-- Name: HOST uk_l0096l0493vnppag4f75m7rmd; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOST"
    ADD CONSTRAINT uk_l0096l0493vnppag4f75m7rmd UNIQUE ("HARDWARE_ID");


--
-- Name: TARGET uk_nj07pogh0o15ymopp12fyeiv3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT uk_nj07pogh0o15ymopp12fyeiv3 UNIQUE ("NAME");


--
-- Name: MAIL_RECIPIENT uk_r9reno3xcy5lwlfxbvcn05mp2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_RECIPIENT"
    ADD CONSTRAINT uk_r9reno3xcy5lwlfxbvcn05mp2 UNIQUE ("EMAIL");


--
-- Name: TARGET_GROUP uk_t6og88u1y7tv5f5ot1kq0i1bt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_GROUP"
    ADD CONSTRAINT uk_t6og88u1y7tv5f5ot1kq0i1bt UNIQUE ("NAME");


--
-- Name: MONITOR unique_monitor_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MONITOR"
    ADD CONSTRAINT unique_monitor_name UNIQUE ("NAME");


--
-- Name: activation_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activation_created_by ON public."ACTIVATION" USING btree ("CREATED_BY");


--
-- Name: activation_license; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activation_license ON public."ACTIVATION" USING btree ("LICENSE");


--
-- Name: activation_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activation_modified_by ON public."ACTIVATION" USING btree ("MODIFIED_BY");


--
-- Name: activation_product_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activation_product_key ON public."ACTIVATION" USING btree ("PRODUCT_KEY");


--
-- Name: activationhis_license; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activationhis_license ON public."ACTIVATION_HISTORY" USING btree ("LICENSE");


--
-- Name: activationhis_product_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX activationhis_product_key ON public."ACTIVATION_HISTORY" USING btree ("PRODUCT_KEY");


--
-- Name: advanced_search_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advanced_search_created_by ON public."ADVANCED_SEARCH" USING btree ("CREATED_BY");


--
-- Name: advanced_search_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX advanced_search_modified_by ON public."ADVANCED_SEARCH" USING btree ("MODIFIED_BY");


--
-- Name: app_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX app_status ON public."APP" USING btree ("STATUS");


--
-- Name: attribute_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_created_by ON public."ATTRIBUTE" USING btree ("CREATED_BY");


--
-- Name: attribute_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_modified_by ON public."ATTRIBUTE" USING btree ("MODIFIED_BY");


--
-- Name: attribute_parameter_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_attribute ON public."ATTRIBUTE_PARAMETER" USING btree ("ATTRIBUTE");


--
-- Name: attribute_parameter_attribute_parameter_set; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_attribute_parameter_set ON public."ATTRIBUTE_PARAMETER" USING btree ("ATTRIBUTE_PARAMETER_SET");


--
-- Name: attribute_parameter_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_created_by ON public."ATTRIBUTE_PARAMETER" USING btree ("CREATED_BY");


--
-- Name: attribute_parameter_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_modified_by ON public."ATTRIBUTE_PARAMETER" USING btree ("MODIFIED_BY");


--
-- Name: attribute_parameter_parameter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_parameter ON public."PARAMETER" USING btree ("ATTRIBUTE_PARAMETER");


--
-- Name: attribute_parameter_set_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_set_created_by ON public."ATTRIBUTE_PARAMETER_SET" USING btree ("CREATED_BY");


--
-- Name: attribute_parameter_set_inherit_from; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_set_inherit_from ON public."ATTRIBUTE_PARAMETER_SET" USING btree ("INHERIT_FROM");


--
-- Name: attribute_parameter_set_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_set_modified_by ON public."ATTRIBUTE_PARAMETER_SET" USING btree ("MODIFIED_BY");


--
-- Name: attribute_parameter_set_source_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_set_source_entity ON public."ATTRIBUTE_PARAMETER_SET" USING btree ("SOURCE_ENTITY");


--
-- Name: attribute_parameter_set_virtual_directory; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attribute_parameter_set_virtual_directory ON public."ATTRIBUTE_PARAMETER_SET" USING btree ("VIRTUAL_DIRECTORY");


--
-- Name: choice_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX choice_created_by ON public."CHOICE" USING btree ("CREATED_BY");


--
-- Name: choice_list_choice; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX choice_list_choice ON public."CHOICE" USING btree ("CHOICE_LIST");


--
-- Name: choice_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX choice_modified_by ON public."CHOICE" USING btree ("MODIFIED_BY");


--
-- Name: choices_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX choices_created_by ON public."CHOICE_LIST" USING btree ("CREATED_BY");


--
-- Name: choices_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX choices_modified_by ON public."CHOICE_LIST" USING btree ("MODIFIED_BY");


--
-- Name: component_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_created_by ON public."COMPONENT" USING btree ("CREATED_BY");


--
-- Name: component_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_modified_by ON public."COMPONENT" USING btree ("MODIFIED_BY");


--
-- Name: component_process_component; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_process_component ON public."COMPONENT_PROCESS" USING btree ("COMPONENT");


--
-- Name: component_process_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_process_created_by ON public."COMPONENT_PROCESS" USING btree ("CREATED_BY");


--
-- Name: component_process_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_process_modified_by ON public."COMPONENT_PROCESS" USING btree ("MODIFIED_BY");


--
-- Name: component_release; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX component_release ON public."COMPONENT" USING btree ("RELEASE");


--
-- Name: configuration_bundle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_bundle ON public."CONFIGURATION" USING btree ("BUNDLE");


--
-- Name: configuration_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_created_by ON public."CONFIGURATION" USING btree ("CREATED_BY");


--
-- Name: configuration_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_modified_by ON public."CONFIGURATION" USING btree ("MODIFIED_BY");


--
-- Name: configuration_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_name ON public."CONFIGURATION" USING btree ("NAME");


--
-- Name: configuration_snapshot_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_created_by ON public."CONFIGURATION_SNAPSHOT" USING btree ("CREATED_BY");


--
-- Name: configuration_snapshot_history; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_history ON public."CONFIGURATION_SNAPSHOT_HISTORY" USING btree ("CONFIGURATION_SNAPSHOT_ID");


--
-- Name: configuration_snapshot_history_component; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_history_component ON public."CONFIGURATION_SNAPSHOT_HISTORY" USING btree ("COMPONENT_ID");


--
-- Name: configuration_snapshot_history_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_history_created_by ON public."CONFIGURATION_SNAPSHOT_HISTORY" USING btree ("CREATED_BY");


--
-- Name: configuration_snapshot_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_modified_by ON public."CONFIGURATION_SNAPSHOT" USING btree ("MODIFIED_BY");


--
-- Name: configuration_snapshot_parent_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX configuration_snapshot_parent_idx ON public."CONFIGURATION_SNAPSHOT" USING btree ("PARENT");


--
-- Name: deployment_component_component; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_component_component ON public."DEPLOYMENT_COMPONENT" USING btree ("COMPONENT");


--
-- Name: deployment_component_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_component_created_by ON public."DEPLOYMENT_COMPONENT" USING btree ("CREATED_BY");


--
-- Name: deployment_component_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_component_modified_by ON public."DEPLOYMENT_COMPONENT" USING btree ("MODIFIED_BY");


--
-- Name: deployment_component_target; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_component_target ON public."DEPLOYMENT_COMPONENT" USING btree ("TARGET");


--
-- Name: deployment_configuration_snapshot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_configuration_snapshot ON public."DEPLOYMENT_CONFIGURATION_SNAPSHOT" USING btree ("DEPLOYMENT_ID");


--
-- Name: deployment_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_created_by ON public."DEPLOYMENT" USING btree ("CREATED_BY");


--
-- Name: deployment_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_modified_by ON public."DEPLOYMENT" USING btree ("MODIFIED_BY");


--
-- Name: deployment_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_parent ON public."DEPLOYMENT" USING btree ("PARENT");


--
-- Name: deployment_release; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX deployment_release ON public."DEPLOYMENT" USING btree ("RELEASE");


--
-- Name: display_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX display_created_by ON public."DISPLAY" USING btree ("CREATED_BY");


--
-- Name: display_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX display_modified_by ON public."DISPLAY" USING btree ("MODIFIED_BY");


--
-- Name: entity_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_created_by ON public."ENTITY" USING btree ("CREATED_BY");


--
-- Name: entity_entity_instance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_entity_instance ON public."ENTITY_INSTANCE" USING btree ("ENTITY");


--
-- Name: entity_form_attribute_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_form_attribute_attribute ON public."ENTITY_FORM_ATTRIBUTE" USING btree ("ATTRIBUTE");


--
-- Name: entity_form_attribute_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_form_attribute_created_by ON public."ENTITY_FORM_ATTRIBUTE" USING btree ("CREATED_BY");


--
-- Name: entity_form_attribute_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_form_attribute_modified_by ON public."ENTITY_FORM_ATTRIBUTE" USING btree ("MODIFIED_BY");


--
-- Name: entity_form_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_form_created_by ON public."ENTITY_FORM" USING btree ("CREATED_BY");


--
-- Name: entity_form_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_form_modified_by ON public."ENTITY_FORM" USING btree ("MODIFIED_BY");


--
-- Name: entity_instance_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_instance_created_by ON public."ENTITY_INSTANCE" USING btree ("CREATED_BY");


--
-- Name: entity_instance_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_instance_modified_by ON public."ENTITY_INSTANCE" USING btree ("MODIFIED_BY");


--
-- Name: entity_instance_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_instance_order ON public."ENTITY_INSTANCE" USING btree ("ORDER");


--
-- Name: entity_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_modified_by ON public."ENTITY" USING btree ("MODIFIED_BY");


--
-- Name: feature_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX feature_created_by ON public."FEATURE" USING btree ("CREATED_BY");


--
-- Name: feature_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX feature_modified_by ON public."FEATURE" USING btree ("MODIFIED_BY");


--
-- Name: feature_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX feature_product ON public."FEATURE" USING btree ("PRODUCT");


--
-- Name: federated_search_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX federated_search_created_by ON public."FEDERATED_SEARCH" USING btree ("CREATED_BY");


--
-- Name: federated_search_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX federated_search_modified_by ON public."FEDERATED_SEARCH" USING btree ("MODIFIED_BY");


--
-- Name: file_system_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_system_created_by ON public."FILE_SYSTEM" USING btree ("CREATED_BY");


--
-- Name: file_system_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_system_modified_by ON public."FILE_SYSTEM" USING btree ("MODIFIED_BY");


--
-- Name: file_system_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_system_name ON public."FILE_SYSTEM" USING btree ("NAME");


--
-- Name: file_system_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_system_provider ON public."FILE_SYSTEM" USING btree ("PROVIDER");


--
-- Name: gateway_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gateway_created ON public."GATEWAY" USING btree ("CREATED_BY");


--
-- Name: gateway_modified; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX gateway_modified ON public."GATEWAY" USING btree ("MODIFIED_BY");


--
-- Name: host_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX host_created_by ON public."HOST" USING btree ("CREATED_BY");


--
-- Name: host_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX host_modified_by ON public."HOST" USING btree ("MODIFIED_BY");


--
-- Name: hotkey_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hotkey_created_by ON public."HOTKEY" USING btree ("CREATED_BY");


--
-- Name: hotkey_extension; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hotkey_extension ON public."HOTKEY" USING btree ("EXTENSION");


--
-- Name: hotkey_hotkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hotkey_hotkey ON public."HOTKEY" USING btree ("HOTKEY");


--
-- Name: hotkey_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hotkey_modified_by ON public."HOTKEY" USING btree ("MODIFIED_BY");


--
-- Name: hotkey_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hotkey_order ON public."HOTKEY" USING btree ("ORDER");


--
-- Name: index_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_status ON public."SEARCH_INDEX" USING btree ("STATUS");


--
-- Name: job_alias; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_alias ON public."JOB" USING btree ("ALIAS");


--
-- Name: job_bundle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_bundle ON public."JOB" USING btree ("BUNDLE");


--
-- Name: job_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_created_by ON public."JOB" USING btree ("CREATED_BY");


--
-- Name: job_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX job_modified_by ON public."JOB" USING btree ("MODIFIED_BY");


--
-- Name: license_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_created_by ON public."LICENSE" USING btree ("CREATED_BY");


--
-- Name: license_feature; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_feature ON public."LICENSE" USING btree ("FEATURE");


--
-- Name: license_key_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_key_created_by ON public."LICENSE_KEY" USING btree ("CREATED_BY");


--
-- Name: license_key_feature_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_key_feature_id ON public."LICENSE_KEY" USING btree ("FEATURE_ID");


--
-- Name: license_key_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_key_key ON public."LICENSE_KEY" USING btree ("KEY");


--
-- Name: license_key_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_key_modified_by ON public."LICENSE_KEY" USING btree ("MODIFIED_BY");


--
-- Name: license_key_node; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_key_node ON public."LICENSE_KEY" USING btree ("NODE");


--
-- Name: license_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_modified_by ON public."LICENSE" USING btree ("MODIFIED_BY");


--
-- Name: license_product_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX license_product_key ON public."LICENSE" USING btree ("PRODUCT_KEY");


--
-- Name: mail_recipient_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX mail_recipient_created_by ON public."MAIL_RECIPIENT" USING btree ("CREATED_BY");


--
-- Name: mail_recipient_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX mail_recipient_modified_by ON public."MAIL_RECIPIENT" USING btree ("MODIFIED_BY");


--
-- Name: mail_server_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX mail_server_created_by ON public."MAIL_SERVER" USING btree ("CREATED_BY");


--
-- Name: mail_server_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX mail_server_modified_by ON public."MAIL_SERVER" USING btree ("MODIFIED_BY");


--
-- Name: monitor_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX monitor_created_by ON public."MONITOR" USING btree ("CREATED_BY");


--
-- Name: monitor_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX monitor_modified_by ON public."MONITOR" USING btree ("MODIFIED_BY");


--
-- Name: node_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_created_by ON public."NODE" USING btree ("CREATED_BY");


--
-- Name: node_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_modified_by ON public."NODE" USING btree ("MODIFIED_BY");


--
-- Name: node_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_name ON public."NODE" USING btree ("NAME");


--
-- Name: node_status_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_status_created_by ON public."NODE_STATUS" USING btree ("CREATED_BY");


--
-- Name: node_status_destination; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_status_destination ON public."NODE_STATUS" USING btree ("DESTINATION");


--
-- Name: node_status_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_status_modified_by ON public."NODE_STATUS" USING btree ("MODIFIED_BY");


--
-- Name: node_status_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX node_status_source ON public."NODE_STATUS" USING btree ("SOURCE");


--
-- Name: ogp_menu_group_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ogp_menu_group_created_by ON public."OGP_MENU_GROUP" USING btree ("CREATED_BY");


--
-- Name: ogp_menu_group_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ogp_menu_group_modified_by ON public."OGP_MENU_GROUP" USING btree ("MODIFIED_BY");


--
-- Name: ogp_menu_group_ogp_entity_form; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ogp_menu_group_ogp_entity_form ON public."OGP_ENTITY_FORM" USING btree ("OGP_MENU_GROUP");


--
-- Name: parameter_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameter_created_by ON public."PARAMETER" USING btree ("CREATED_BY");


--
-- Name: parameter_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameter_modified_by ON public."PARAMETER" USING btree ("MODIFIED_BY");


--
-- Name: parameter_set_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameter_set_created_by ON public."PARAMETER_SET" USING btree ("CREATED_BY");


--
-- Name: parameter_set_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameter_set_modified_by ON public."PARAMETER_SET" USING btree ("MODIFIED_BY");


--
-- Name: parameter_set_parameter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX parameter_set_parameter ON public."PARAMETER" USING btree ("PARAMETER_SET");


--
-- Name: permission_bundle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_bundle ON public."PERMISSION" USING btree ("BUNDLE");


--
-- Name: permission_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_created_by ON public."PERMISSION" USING btree ("CREATED_BY");


--
-- Name: permission_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_modified_by ON public."PERMISSION" USING btree ("MODIFIED_BY");


--
-- Name: permission_object; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_object ON public."PERMISSION" USING btree ("OBJECT");


--
-- Name: permission_permission; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_permission ON public."PERMISSION" USING btree ("PERMISSION");


--
-- Name: permission_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_role ON public."PERMISSION" USING btree ("ROLE");


--
-- Name: permission_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX permission_scope ON public."PERMISSION" USING btree ("SCOPE");


--
-- Name: perspective_column_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_column_created_by ON public."PERSPECTIVE_COLUMN" USING btree ("CREATED_BY");


--
-- Name: perspective_column_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_column_modified_by ON public."PERSPECTIVE_COLUMN" USING btree ("MODIFIED_BY");


--
-- Name: perspective_column_perspective; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_column_perspective ON public."PERSPECTIVE_COLUMN" USING btree ("PERSPECTIVE");


--
-- Name: perspective_column_view; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_column_view ON public."PERSPECTIVE_COLUMN" USING btree ("VIEW");


--
-- Name: perspective_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_created_by ON public."PERSPECTIVE" USING btree ("CREATED_BY");


--
-- Name: perspective_field_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_field_created_by ON public."PERSPECTIVE_FIELD" USING btree ("CREATED_BY");


--
-- Name: perspective_field_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_field_modified_by ON public."PERSPECTIVE_FIELD" USING btree ("MODIFIED_BY");


--
-- Name: perspective_field_perspective; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_field_perspective ON public."PERSPECTIVE_FIELD" USING btree ("PERSPECTIVE");


--
-- Name: perspective_field_view; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_field_view ON public."PERSPECTIVE_FIELD" USING btree ("VIEW");


--
-- Name: perspective_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_modified_by ON public."PERSPECTIVE" USING btree ("MODIFIED_BY");


--
-- Name: perspective_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_user ON public."PERSPECTIVE" USING btree ("USER");


--
-- Name: perspective_workbench; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX perspective_workbench ON public."PERSPECTIVE" USING btree ("WORKBENCH");


--
-- Name: preference_bundle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX preference_bundle ON public."PREFERENCE" USING btree ("BUNDLE");


--
-- Name: preference_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX preference_created_by ON public."PREFERENCE" USING btree ("CREATED_BY");


--
-- Name: preference_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX preference_modified_by ON public."PREFERENCE" USING btree ("MODIFIED_BY");


--
-- Name: preference_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX preference_name ON public."PREFERENCE" USING btree ("NAME");


--
-- Name: preference_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX preference_user ON public."PREFERENCE" USING btree ("USER");


--
-- Name: product_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_created_by ON public."PRODUCT" USING btree ("CREATED_BY");


--
-- Name: product_key_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_key_created_by ON public."PRODUCT_KEY" USING btree ("CREATED_BY");


--
-- Name: product_key_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_key_modified_by ON public."PRODUCT_KEY" USING btree ("MODIFIED_BY");


--
-- Name: product_key_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_key_parent ON public."PRODUCT_KEY" USING btree ("PARENT");


--
-- Name: product_key_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_key_product ON public."PRODUCT_KEY" USING btree ("PRODUCT");


--
-- Name: product_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_modified_by ON public."PRODUCT" USING btree ("MODIFIED_BY");


--
-- Name: release_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX release_created_by ON public."RELEASE" USING btree ("CREATED_BY");


--
-- Name: release_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX release_modified_by ON public."RELEASE" USING btree ("MODIFIED_BY");


--
-- Name: release_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX release_product ON public."RELEASE" USING btree ("PRODUCT");


--
-- Name: report_active_node; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_active_node ON public."REPORT_RUN" USING btree ("ACTIVE_NODE");


--
-- Name: report_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_created_by ON public."REPORT" USING btree ("CREATED_BY");


--
-- Name: report_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_modified_by ON public."REPORT" USING btree ("MODIFIED_BY");


--
-- Name: report_run_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_run_created_by ON public."REPORT_RUN" USING btree ("CREATED_BY");


--
-- Name: report_run_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX report_run_modified_by ON public."REPORT_RUN" USING btree ("MODIFIED_BY");


--
-- Name: role_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX role_created_by ON public."ROLE" USING btree ("CREATED_BY");


--
-- Name: role_domain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX role_domain ON public."ROLE" USING btree ("DOMAIN");


--
-- Name: role_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX role_modified_by ON public."ROLE" USING btree ("MODIFIED_BY");


--
-- Name: snapshot_history_target; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX snapshot_history_target ON public."CONFIGURATION_SNAPSHOT_HISTORY" USING btree ("TARGET_ID");


--
-- Name: snapshot_snapshot_history_source_target; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX snapshot_snapshot_history_source_target ON public."CONFIGURATION_SNAPSHOT_HISTORY" USING btree ("SOURCE_TARGET_ID");


--
-- Name: target_configuration_snapshot; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_configuration_snapshot ON public."TARGET_CONFIGURATION_SNAPSHOT" USING btree ("TARGET_ID");


--
-- Name: target_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_created_by ON public."TARGET" USING btree ("CREATED_BY");


--
-- Name: target_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_modified_by ON public."TARGET" USING btree ("MODIFIED_BY");


--
-- Name: target_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_parent ON public."TARGET" USING btree ("PARENT");


--
-- Name: target_remote_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_remote_key ON public."TARGET" USING btree ("REMOTE_KEY");


--
-- Name: target_target_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX target_target_group ON public."TARGET" USING btree ("TARGET_GROUP");


--
-- Name: user_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_created_by ON public."USER" USING btree ("CREATED_BY");


--
-- Name: user_domain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_domain ON public."USER" USING btree ("DOMAIN");


--
-- Name: user_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_email ON public."USER" USING btree ("EMAIL");


--
-- Name: user_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_modified_by ON public."USER" USING btree ("MODIFIED_BY");


--
-- Name: user_session_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_session_created_by ON public."USER_SESSION" USING btree ("CREATED_BY");


--
-- Name: user_session_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_session_modified_by ON public."USER_SESSION" USING btree ("MODIFIED_BY");


--
-- Name: user_session_node; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_session_node ON public."USER_SESSION" USING btree ("NODE");


--
-- Name: user_session_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_session_user ON public."USER_SESSION" USING btree ("USER");


--
-- Name: user_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_username ON public."USER" USING btree ("USERNAME");


--
-- Name: user_watermark_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_watermark_created_by ON public."USER_WATERMARK_MONITOR" USING btree ("CREATED_BY");


--
-- Name: user_watermark_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_watermark_modified_by ON public."USER_WATERMARK_MONITOR" USING btree ("MODIFIED_BY");


--
-- Name: view_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_created_by ON public."VIEW" USING btree ("CREATED_BY");


--
-- Name: view_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_modified_by ON public."VIEW" USING btree ("MODIFIED_BY");


--
-- Name: view_property_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_property_created_by ON public."VIEW_PROPERTY" USING btree ("CREATED_BY");


--
-- Name: view_property_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_property_modified_by ON public."VIEW_PROPERTY" USING btree ("MODIFIED_BY");


--
-- Name: view_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_user ON public."VIEW" USING btree ("USER");


--
-- Name: viewport_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX viewport_created_by ON public."VIEWPORT" USING btree ("CREATED_BY");


--
-- Name: viewport_focused; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX viewport_focused ON public."VIEWPORT" USING btree ("FOCUSED");


--
-- Name: viewport_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX viewport_modified_by ON public."VIEWPORT" USING btree ("MODIFIED_BY");


--
-- Name: viewport_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX viewport_user ON public."VIEWPORT" USING btree ("USER");


--
-- Name: virtual_directory_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX virtual_directory_created_by ON public."VIRTUAL_DIRECTORY" USING btree ("CREATED_BY");


--
-- Name: virtual_directory_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX virtual_directory_modified_by ON public."VIRTUAL_DIRECTORY" USING btree ("MODIFIED_BY");


--
-- Name: virtual_directory_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX virtual_directory_parent ON public."VIRTUAL_DIRECTORY" USING btree ("PARENT");


--
-- Name: visual_workflow_job_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX visual_workflow_job_created_by ON public."VISUAL_WORKFLOW_JOB" USING btree ("CREATED_BY");


--
-- Name: visual_workflow_job_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX visual_workflow_job_modified_by ON public."VISUAL_WORKFLOW_JOB" USING btree ("MODIFIED_BY");


--
-- Name: visual_workflow_job_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX visual_workflow_job_parent ON public."VISUAL_WORKFLOW_JOB" USING btree ("PARENT");


--
-- Name: visual_workflow_job_run_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX visual_workflow_job_run_created_by ON public."VISUAL_WORKFLOW_JOB_RUN" USING btree ("CREATED_BY");


--
-- Name: visual_workflow_job_run_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX visual_workflow_job_run_modified_by ON public."VISUAL_WORKFLOW_JOB_RUN" USING btree ("MODIFIED_BY");


--
-- Name: vwf_node_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX vwf_node_created_by ON public."VISUAL_WORKFLOW_NODE" USING btree ("CREATED_BY");


--
-- Name: vwf_node_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX vwf_node_modified_by ON public."VISUAL_WORKFLOW_NODE" USING btree ("MODIFIED_BY");


--
-- Name: vwf_node_vwf_job; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX vwf_node_vwf_job ON public."VISUAL_WORKFLOW_NODE" USING btree ("JOB");


--
-- Name: vwf_socket_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX vwf_socket_created_by ON public."VISUAL_WORKFLOW_SOCKET" USING btree ("CREATED_BY");


--
-- Name: vwf_socket_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX vwf_socket_modified_by ON public."VISUAL_WORKFLOW_SOCKET" USING btree ("MODIFIED_BY");


--
-- Name: workspace_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workspace_created_by ON public."WORKSPACE" USING btree ("CREATED_BY");


--
-- Name: workspace_modified_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workspace_modified_by ON public."WORKSPACE" USING btree ("MODIFIED_BY");


--
-- Name: workspace_perspective; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workspace_perspective ON public."WORKSPACE" USING btree ("PERSPECTIVE");


--
-- Name: workspace_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workspace_user ON public."WORKSPACE" USING btree ("USER");


--
-- Name: workspace_workbench; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX workspace_workbench ON public."WORKSPACE" USING btree ("WORKBENCH");


--
-- Name: MAIL_RECIPIENT FK2wfp9c175g8bx1xq8gwn2pc71; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_RECIPIENT"
    ADD CONSTRAINT "FK2wfp9c175g8bx1xq8gwn2pc71" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PRODUCT_KEY FK7uclq9ka643ysbxulmyh29b5l; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT "FK7uclq9ka643ysbxulmyh29b5l" FOREIGN KEY ("PRODUCT") REFERENCES public."PRODUCT"("ID");


--
-- Name: FEATURE FK9iylmqfgmpja2oray868wtln7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE"
    ADD CONSTRAINT "FK9iylmqfgmpja2oray868wtln7" FOREIGN KEY ("PRODUCT") REFERENCES public."PRODUCT"("ID");


--
-- Name: ACTIVATION FK_ACTIVATION_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "FK_ACTIVATION_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ACTIVATION_HISTORY FK_ACTIVATION_HISTORY_LICENSE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_HISTORY"
    ADD CONSTRAINT "FK_ACTIVATION_HISTORY_LICENSE" FOREIGN KEY ("LICENSE") REFERENCES public."LICENSE"("ID");


--
-- Name: ACTIVATION_HISTORY FK_ACTIVATION_HISTORY_PRODUCT_KEY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION_HISTORY"
    ADD CONSTRAINT "FK_ACTIVATION_HISTORY_PRODUCT_KEY" FOREIGN KEY ("PRODUCT_KEY") REFERENCES public."PRODUCT_KEY"("ID");


--
-- Name: ACTIVATION FK_ACTIVATION_LICENSE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "FK_ACTIVATION_LICENSE" FOREIGN KEY ("LICENSE") REFERENCES public."LICENSE"("ID");


--
-- Name: ACTIVATION FK_ACTIVATION_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "FK_ACTIVATION_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ACTIVATION FK_ACTIVATION_PRODUCT_KEY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ACTIVATION"
    ADD CONSTRAINT "FK_ACTIVATION_PRODUCT_KEY" FOREIGN KEY ("PRODUCT_KEY") REFERENCES public."PRODUCT_KEY"("ID");


--
-- Name: ADVANCED_SEARCH FK_ADVANCED_SEARCH_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ADVANCED_SEARCH"
    ADD CONSTRAINT "FK_ADVANCED_SEARCH_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ADVANCED_SEARCH FK_ADVANCED_SEARCH_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ADVANCED_SEARCH"
    ADD CONSTRAINT "FK_ADVANCED_SEARCH_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_FORM_ATTRIBUTE FK_ATTRIBUTES_ENTITY_FORM_ATTRIBUTES; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE"
    ADD CONSTRAINT "FK_ATTRIBUTES_ENTITY_FORM_ATTRIBUTES" FOREIGN KEY ("ENTITY_FORM") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: ATTRIBUTE FK_ATTRIBUTE_CHOICE_LIST; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE"
    ADD CONSTRAINT "FK_ATTRIBUTE_CHOICE_LIST" FOREIGN KEY ("CHOICE_LIST") REFERENCES public."CHOICE_LIST"("ID");


--
-- Name: ATTRIBUTE FK_ATTRIBUTE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE"
    ADD CONSTRAINT "FK_ATTRIBUTE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ATTRIBUTE FK_ATTRIBUTE_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE"
    ADD CONSTRAINT "FK_ATTRIBUTE_ENTITY" FOREIGN KEY ("ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ATTRIBUTE FK_ATTRIBUTE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE"
    ADD CONSTRAINT "FK_ATTRIBUTE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ATTRIBUTE_PARAMETER FK_ATTRIBUTE_PARAMETER_ATTRIBUTE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_ATTRIBUTE" FOREIGN KEY ("ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: ATTRIBUTE_PARAMETER FK_ATTRIBUTE_PARAMETER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ATTRIBUTE_PARAMETER FK_ATTRIBUTE_PARAMETER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER FK_ATTRIBUTE_PARAMETER_PARAMETER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_PARAMETER" FOREIGN KEY ("ATTRIBUTE_PARAMETER") REFERENCES public."ATTRIBUTE_PARAMETER"("ID");


--
-- Name: ATTRIBUTE_PARAMETER FK_ATTRIBUTE_PARAMETER_SET_ATTRIBUTE_PARAMETER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_ATTRIBUTE_PARAMETER" FOREIGN KEY ("ATTRIBUTE_PARAMETER_SET") REFERENCES public."ATTRIBUTE_PARAMETER_SET"("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET FK_ATTRIBUTE_PARAMETER_SET_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET FK_ATTRIBUTE_PARAMETER_SET_INHERIT_FROM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_INHERIT_FROM" FOREIGN KEY ("INHERIT_FROM") REFERENCES public."ATTRIBUTE_PARAMETER_SET"("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET FK_ATTRIBUTE_PARAMETER_SET_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET FK_ATTRIBUTE_PARAMETER_SET_SOURCE_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_SOURCE_ENTITY" FOREIGN KEY ("SOURCE_ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ATTRIBUTE_PARAMETER_SET FK_ATTRIBUTE_PARAMETER_SET_VIRTUAL_DIRECTORY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ATTRIBUTE_PARAMETER_SET"
    ADD CONSTRAINT "FK_ATTRIBUTE_PARAMETER_SET_VIRTUAL_DIRECTORY" FOREIGN KEY ("VIRTUAL_DIRECTORY") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: CHOICE FK_CHOICE_CHOICE_LIST; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE"
    ADD CONSTRAINT "FK_CHOICE_CHOICE_LIST" FOREIGN KEY ("CHOICE_LIST") REFERENCES public."CHOICE_LIST"("ID");


--
-- Name: CHOICE FK_CHOICE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE"
    ADD CONSTRAINT "FK_CHOICE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: CHOICE_LIST FK_CHOICE_LIST_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE_LIST"
    ADD CONSTRAINT "FK_CHOICE_LIST_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: CHOICE_LIST FK_CHOICE_LIST_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE_LIST"
    ADD CONSTRAINT "FK_CHOICE_LIST_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: CHOICE FK_CHOICE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CHOICE"
    ADD CONSTRAINT "FK_CHOICE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: CLOUD_TARGET FK_CLOUD_TARGET_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CLOUD_TARGET"
    ADD CONSTRAINT "FK_CLOUD_TARGET_ID" FOREIGN KEY ("ID") REFERENCES public."TARGET"("ID");


--
-- Name: COMPONENT FK_COMPONENT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT"
    ADD CONSTRAINT "FK_COMPONENT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: COMPONENT FK_COMPONENT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT"
    ADD CONSTRAINT "FK_COMPONENT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: COMPONENT_PROCESS FK_COMPONENT_PROCESS_COMPONENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT_PROCESS"
    ADD CONSTRAINT "FK_COMPONENT_PROCESS_COMPONENT" FOREIGN KEY ("COMPONENT") REFERENCES public."COMPONENT"("ID");


--
-- Name: COMPONENT_PROCESS FK_COMPONENT_PROCESS_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT_PROCESS"
    ADD CONSTRAINT "FK_COMPONENT_PROCESS_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: COMPONENT_PROCESS FK_COMPONENT_PROCESS_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT_PROCESS"
    ADD CONSTRAINT "FK_COMPONENT_PROCESS_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: COMPONENT FK_COMPONENT_RELEASE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."COMPONENT"
    ADD CONSTRAINT "FK_COMPONENT_RELEASE" FOREIGN KEY ("RELEASE") REFERENCES public."RELEASE"("ID");


--
-- Name: CONFIGURATION FK_CONFIGURATION_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION"
    ADD CONSTRAINT "FK_CONFIGURATION_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: CONFIGURATION FK_CONFIGURATION_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION"
    ADD CONSTRAINT "FK_CONFIGURATION_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT FK_CONFIGURATION_SNAPSHOT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY FK_CONFIGURATION_SNAPSHOT_HISTORY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_HISTORY" FOREIGN KEY ("CONFIGURATION_SNAPSHOT_ID") REFERENCES public."CONFIGURATION_SNAPSHOT"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY FK_CONFIGURATION_SNAPSHOT_HISTORY_COMPONENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_HISTORY_COMPONENT" FOREIGN KEY ("COMPONENT_ID") REFERENCES public."COMPONENT"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY FK_CONFIGURATION_SNAPSHOT_HISTORY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_HISTORY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT FK_CONFIGURATION_SNAPSHOT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT FK_CONFIGURATION_SNAPSHOT_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_CONFIGURATION_SNAPSHOT_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: CUSTOM_PANEL_FILE FK_CUSTOM_PANEL_FILE_CUSTOM_PANEL_NAMESPACE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CUSTOM_PANEL_FILE"
    ADD CONSTRAINT "FK_CUSTOM_PANEL_FILE_CUSTOM_PANEL_NAMESPACE" FOREIGN KEY ("CUSTOM_PANEL_NAMESPACE_ID") REFERENCES public."CUSTOM_PANEL_NAMESPACE"("ID");


--
-- Name: DEPLOYMENT_COMPONENT FK_DEPLOYMENT_COMPONENT_COMPONENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_COMPONENT_COMPONENT" FOREIGN KEY ("COMPONENT") REFERENCES public."COMPONENT"("ID");


--
-- Name: DEPLOYMENT_COMPONENT FK_DEPLOYMENT_COMPONENT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_COMPONENT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: DEPLOYMENT_COMPONENT FK_DEPLOYMENT_COMPONENT_DEPLOYMENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_COMPONENT_DEPLOYMENT" FOREIGN KEY ("DEPLOYMENT") REFERENCES public."DEPLOYMENT"("ID");


--
-- Name: DEPLOYMENT_COMPONENT FK_DEPLOYMENT_COMPONENT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_COMPONENT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: DEPLOYMENT_COMPONENT FK_DEPLOYMENT_COMPONENT_TARGET; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_COMPONENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_COMPONENT_TARGET" FOREIGN KEY ("TARGET") REFERENCES public."TARGET"("ID");


--
-- Name: DEPLOYMENT_CONFIGURATION_SNAPSHOT FK_DEPLOYMENT_CONFIGURATION_SNAPSHOT_DEPLOYMENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_DEPLOYMENT_CONFIGURATION_SNAPSHOT_DEPLOYMENT" FOREIGN KEY ("DEPLOYMENT_ID") REFERENCES public."DEPLOYMENT"("ID");


--
-- Name: DEPLOYMENT_CONFIGURATION_SNAPSHOT FK_DEPLOYMENT_CONFIGURATION_SNAPSHOT_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_DEPLOYMENT_CONFIGURATION_SNAPSHOT_ID" FOREIGN KEY ("ID") REFERENCES public."CONFIGURATION_SNAPSHOT"("ID");


--
-- Name: DEPLOYMENT FK_DEPLOYMENT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: DEPLOYMENT FK_DEPLOYMENT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: DEPLOYMENT FK_DEPLOYMENT_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: DEPLOYMENT FK_DEPLOYMENT_RELEASE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DEPLOYMENT"
    ADD CONSTRAINT "FK_DEPLOYMENT_RELEASE" FOREIGN KEY ("RELEASE") REFERENCES public."RELEASE"("ID");


--
-- Name: DISK_USAGE_MONITOR FK_DISK_USAGE_MONITOR_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISK_USAGE_MONITOR"
    ADD CONSTRAINT "FK_DISK_USAGE_MONITOR_ID" FOREIGN KEY ("ID") REFERENCES public."MONITOR"("ID");


--
-- Name: DISPLAY_ATTRIBUTE FK_DISPLAY_ATTRIBUTE_ATTRIBUTE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY_ATTRIBUTE"
    ADD CONSTRAINT "FK_DISPLAY_ATTRIBUTE_ATTRIBUTE" FOREIGN KEY ("ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: DISPLAY_ATTRIBUTE FK_DISPLAY_ATTRIBUTE_DISPLAY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY_ATTRIBUTE"
    ADD CONSTRAINT "FK_DISPLAY_ATTRIBUTE_DISPLAY" FOREIGN KEY ("DISPLAY") REFERENCES public."DISPLAY"("ID");


--
-- Name: DISPLAY FK_DISPLAY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY"
    ADD CONSTRAINT "FK_DISPLAY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: DISPLAY FK_DISPLAY_MANAGER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY"
    ADD CONSTRAINT "FK_DISPLAY_MANAGER" FOREIGN KEY ("MANAGER") REFERENCES public."MANAGER"("ID");


--
-- Name: DISPLAY FK_DISPLAY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DISPLAY"
    ADD CONSTRAINT "FK_DISPLAY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING FK_ENTITY_CONN_ATTR_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "FK_ENTITY_CONN_ATTR_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING FK_ENTITY_CONN_ATTR_ENTITY_CONN; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "FK_ENTITY_CONN_ATTR_ENTITY_CONN" FOREIGN KEY ("ENTITY_CONNECTION") REFERENCES public."ENTITY_CONNECTION"("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING FK_ENTITY_CONN_ATTR_FROM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "FK_ENTITY_CONN_ATTR_FROM" FOREIGN KEY ("FROM_ENTITY_ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING FK_ENTITY_CONN_ATTR_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "FK_ENTITY_CONN_ATTR_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION_ATTRIBUTE_MAPPING FK_ENTITY_CONN_ATTR_TO; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_ATTRIBUTE_MAPPING"
    ADD CONSTRAINT "FK_ENTITY_CONN_ATTR_TO" FOREIGN KEY ("TO_ENTITY_ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_CREATE_FORM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_CREATE_FORM" FOREIGN KEY ("CREATE_FORM") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_EDIT_FORM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_EDIT_FORM" FOREIGN KEY ("EDIT_FORM") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_FROM_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_FROM_ENTITY" FOREIGN KEY ("FROM_ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ENTITY_CONNECTION_INSTANCE FK_ENTITY_CONN_INSTANCE_CONNECTION; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_CONN_INSTANCE_CONNECTION" FOREIGN KEY ("ENTITY_CONNECTION") REFERENCES public."ENTITY_CONNECTION"("ID");


--
-- Name: ENTITY_CONNECTION_INSTANCE FK_ENTITY_CONN_INSTANCE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_CONN_INSTANCE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION_INSTANCE FK_ENTITY_CONN_INSTANCE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_CONN_INSTANCE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_CONNECTION FK_ENTITY_CONN_TO_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_CONNECTION"
    ADD CONSTRAINT "FK_ENTITY_CONN_TO_ENTITY" FOREIGN KEY ("TO_ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ENTITY FK_ENTITY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY"
    ADD CONSTRAINT "FK_ENTITY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_FORM_ATTRIBUTE FK_ENTITY_FORM_ATTRIBUTE_ATTRIBUTE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE"
    ADD CONSTRAINT "FK_ENTITY_FORM_ATTRIBUTE_ATTRIBUTE" FOREIGN KEY ("ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: ENTITY_FORM_ATTRIBUTE FK_ENTITY_FORM_ATTRIBUTE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE"
    ADD CONSTRAINT "FK_ENTITY_FORM_ATTRIBUTE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_FORM_ATTRIBUTE FK_ENTITY_FORM_ATTRIBUTE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM_ATTRIBUTE"
    ADD CONSTRAINT "FK_ENTITY_FORM_ATTRIBUTE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_FORM FK_ENTITY_FORM_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM"
    ADD CONSTRAINT "FK_ENTITY_FORM_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_FORM FK_ENTITY_FORM_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM"
    ADD CONSTRAINT "FK_ENTITY_FORM_ENTITY" FOREIGN KEY ("ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ENTITY_FORM FK_ENTITY_FORM_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_FORM"
    ADD CONSTRAINT "FK_ENTITY_FORM_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_INSTANCE FK_ENTITY_INSTANCE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_INSTANCE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_INSTANCE FK_ENTITY_INSTANCE_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_INSTANCE_ENTITY" FOREIGN KEY ("ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ENTITY_INSTANCE FK_ENTITY_INSTANCE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_INSTANCE"
    ADD CONSTRAINT "FK_ENTITY_INSTANCE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_CREATE_FORM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_CREATE_FORM" FOREIGN KEY ("CREATE_FORM") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_EDIT_FORM; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_EDIT_FORM" FOREIGN KEY ("EDIT_FORM") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_ENTITY" FOREIGN KEY ("ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_MANAGER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_MANAGER" FOREIGN KEY ("MANAGER") REFERENCES public."MANAGER"("ID");


--
-- Name: ENTITY_MANAGER FK_ENTITY_MANAGER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY_MANAGER"
    ADD CONSTRAINT "FK_ENTITY_MANAGER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY FK_ENTITY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY"
    ADD CONSTRAINT "FK_ENTITY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ENTITY FK_ENTITY_TITLE_ATTRIBUTE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ENTITY"
    ADD CONSTRAINT "FK_ENTITY_TITLE_ATTRIBUTE" FOREIGN KEY ("TITLE_ATTRIBUTE") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: FEATURE FK_FEATURE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE"
    ADD CONSTRAINT "FK_FEATURE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: FEATURE FK_FEATURE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEATURE"
    ADD CONSTRAINT "FK_FEATURE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: FEDERATED_SEARCH FK_FEDERATED_SEARCH_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEDERATED_SEARCH"
    ADD CONSTRAINT "FK_FEDERATED_SEARCH_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: FEDERATED_SEARCH FK_FEDERATED_SEARCH_MODIFIED_B; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FEDERATED_SEARCH"
    ADD CONSTRAINT "FK_FEDERATED_SEARCH_MODIFIED_B" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: FILE_SYSTEM FK_FILE_SYSTEM_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FILE_SYSTEM"
    ADD CONSTRAINT "FK_FILE_SYSTEM_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: FILE_SYSTEM FK_FILE_SYSTEM_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FILE_SYSTEM"
    ADD CONSTRAINT "FK_FILE_SYSTEM_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: GATEWAY FK_GATEWAY_CREATED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GATEWAY"
    ADD CONSTRAINT "FK_GATEWAY_CREATED" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: GATEWAY FK_GATEWAY_MODIFIED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GATEWAY"
    ADD CONSTRAINT "FK_GATEWAY_MODIFIED" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: HOST FK_HOST_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOST"
    ADD CONSTRAINT "FK_HOST_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: HOST FK_HOST_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOST"
    ADD CONSTRAINT "FK_HOST_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: HOTKEY FK_HOTKEY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOTKEY"
    ADD CONSTRAINT "FK_HOTKEY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: HOTKEY FK_HOTKEY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."HOTKEY"
    ADD CONSTRAINT "FK_HOTKEY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: INTERNET_CONN_MONITOR FK_INTERNET_CONN_MONITOR_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."INTERNET_CONN_MONITOR"
    ADD CONSTRAINT "FK_INTERNET_CONN_MONITOR_ID" FOREIGN KEY ("ID") REFERENCES public."MONITOR"("ID");


--
-- Name: JOB FK_JOB_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB"
    ADD CONSTRAINT "FK_JOB_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: JOB FK_JOB_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB"
    ADD CONSTRAINT "FK_JOB_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: JOB_NODE FK_JOB_NODE_JOB; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB_NODE"
    ADD CONSTRAINT "FK_JOB_NODE_JOB" FOREIGN KEY ("JOB") REFERENCES public."JOB"("ID");


--
-- Name: JOB_NODE FK_JOB_NODE_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."JOB_NODE"
    ADD CONSTRAINT "FK_JOB_NODE_NODE" FOREIGN KEY ("NODE") REFERENCES public."NODE"("ID");


--
-- Name: LICENSE_KEY FK_LICENSE_KEY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE_KEY"
    ADD CONSTRAINT "FK_LICENSE_KEY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: LICENSE_KEY FK_LICENSE_KEY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE_KEY"
    ADD CONSTRAINT "FK_LICENSE_KEY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: LICENSE_KEY FK_LICENSE_KEY_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE_KEY"
    ADD CONSTRAINT "FK_LICENSE_KEY_NODE" FOREIGN KEY ("NODE") REFERENCES public."NODE"("ID");


--
-- Name: MAIL_SERVER FK_MAIL_SERVER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_SERVER"
    ADD CONSTRAINT "FK_MAIL_SERVER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: MAIL_SERVER FK_MAIL_SERVER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_SERVER"
    ADD CONSTRAINT "FK_MAIL_SERVER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: MANAGER FK_MANAGER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MANAGER"
    ADD CONSTRAINT "FK_MANAGER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: MANAGER FK_MANAGER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MANAGER"
    ADD CONSTRAINT "FK_MANAGER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: MONITOR FK_MONITOR_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MONITOR"
    ADD CONSTRAINT "FK_MONITOR_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: MONITOR FK_MONITOR_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MONITOR"
    ADD CONSTRAINT "FK_MONITOR_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: NODE FK_NODE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE"
    ADD CONSTRAINT "FK_NODE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: NODE FK_NODE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE"
    ADD CONSTRAINT "FK_NODE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: NODE_STATUS FK_NODE_STATUS_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS"
    ADD CONSTRAINT "FK_NODE_STATUS_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: NODE_STATUS FK_NODE_STATUS_DESTINATION; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS"
    ADD CONSTRAINT "FK_NODE_STATUS_DESTINATION" FOREIGN KEY ("DESTINATION") REFERENCES public."NODE"("ID");


--
-- Name: NODE_STATUS FK_NODE_STATUS_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS"
    ADD CONSTRAINT "FK_NODE_STATUS_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: NODE_STATUS FK_NODE_STATUS_SOURCE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NODE_STATUS"
    ADD CONSTRAINT "FK_NODE_STATUS_SOURCE" FOREIGN KEY ("SOURCE") REFERENCES public."NODE"("ID");


--
-- Name: OGP_ATTRIBUTE FK_OGP_ATTRIBUTE_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_ATTRIBUTE"
    ADD CONSTRAINT "FK_OGP_ATTRIBUTE_ID" FOREIGN KEY ("ID") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: OGP_CHOICE_LIST FK_OGP_CHOICE_LIST_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_CHOICE_LIST"
    ADD CONSTRAINT "FK_OGP_CHOICE_LIST_ID" FOREIGN KEY ("ID") REFERENCES public."CHOICE_LIST"("ID");


--
-- Name: OGP_ENTITY_FORM FK_OGP_ENTITY_FORM_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_ENTITY_FORM"
    ADD CONSTRAINT "FK_OGP_ENTITY_FORM_ID" FOREIGN KEY ("ID") REFERENCES public."ENTITY_FORM"("ID");


--
-- Name: OGP_ENTITY_FORM FK_OGP_ENTITY_FORM_OGP_MENU_GROUP; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_ENTITY_FORM"
    ADD CONSTRAINT "FK_OGP_ENTITY_FORM_OGP_MENU_GROUP" FOREIGN KEY ("OGP_MENU_GROUP") REFERENCES public."OGP_MENU_GROUP"("ID");


--
-- Name: OGP_MENU_GROUP FK_OGP_MENU_GROUP_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_MENU_GROUP"
    ADD CONSTRAINT "FK_OGP_MENU_GROUP_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: OGP_MENU_GROUP FK_OGP_MENU_GROUP_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OGP_MENU_GROUP"
    ADD CONSTRAINT "FK_OGP_MENU_GROUP_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER FK_PARAMETER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER"
    ADD CONSTRAINT "FK_PARAMETER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER FK_PARAMETER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER"
    ADD CONSTRAINT "FK_PARAMETER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER_SET FK_PARAMETER_SET_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER_SET"
    ADD CONSTRAINT "FK_PARAMETER_SET_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER_SET FK_PARAMETER_SET_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER_SET"
    ADD CONSTRAINT "FK_PARAMETER_SET_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PARAMETER FK_PARAMETER_SET_PARAMETER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PARAMETER"
    ADD CONSTRAINT "FK_PARAMETER_SET_PARAMETER" FOREIGN KEY ("PARAMETER_SET") REFERENCES public."PARAMETER_SET"("ID");


--
-- Name: PERMISSION FK_PERMISSION_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION"
    ADD CONSTRAINT "FK_PERMISSION_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERMISSION FK_PERMISSION_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION"
    ADD CONSTRAINT "FK_PERMISSION_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERMISSION FK_PERMISSION_ROLE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION"
    ADD CONSTRAINT "FK_PERMISSION_ROLE" FOREIGN KEY ("ROLE") REFERENCES public."ROLE"("ID");


--
-- Name: PERMISSION FK_PERMISSION_SCOPE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERMISSION"
    ADD CONSTRAINT "FK_PERMISSION_SCOPE" FOREIGN KEY ("SCOPE") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: PERSPECTIVE_COLUMN FK_PERSPECTIVE_COLUMN_CREATED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_COLUMN"
    ADD CONSTRAINT "FK_PERSPECTIVE_COLUMN_CREATED" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE_COLUMN FK_PERSPECTIVE_COLUMN_MODIFIED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_COLUMN"
    ADD CONSTRAINT "FK_PERSPECTIVE_COLUMN_MODIFIED" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE_COLUMN FK_PERSPECTIVE_COLUMN_PERSPECT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_COLUMN"
    ADD CONSTRAINT "FK_PERSPECTIVE_COLUMN_PERSPECT" FOREIGN KEY ("PERSPECTIVE") REFERENCES public."PERSPECTIVE"("ID");


--
-- Name: PERSPECTIVE FK_PERSPECTIVE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE"
    ADD CONSTRAINT "FK_PERSPECTIVE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE_FIELD FK_PERSPECTIVE_FIELD_CREATED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_FIELD"
    ADD CONSTRAINT "FK_PERSPECTIVE_FIELD_CREATED" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE_FIELD FK_PERSPECTIVE_FIELD_MODIFIED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_FIELD"
    ADD CONSTRAINT "FK_PERSPECTIVE_FIELD_MODIFIED" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE_FIELD FK_PERSPECTIVE_FIELD_PERSPECT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE_FIELD"
    ADD CONSTRAINT "FK_PERSPECTIVE_FIELD_PERSPECT" FOREIGN KEY ("PERSPECTIVE") REFERENCES public."PERSPECTIVE"("ID");


--
-- Name: PERSPECTIVE FK_PERSPECTIVE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE"
    ADD CONSTRAINT "FK_PERSPECTIVE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PERSPECTIVE FK_PERSPECTIVE_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PERSPECTIVE"
    ADD CONSTRAINT "FK_PERSPECTIVE_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: PREFERENCE FK_PREFERENCE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PREFERENCE"
    ADD CONSTRAINT "FK_PREFERENCE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PREFERENCE FK_PREFERENCE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PREFERENCE"
    ADD CONSTRAINT "FK_PREFERENCE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PREFERENCE FK_PREFERENCE_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PREFERENCE"
    ADD CONSTRAINT "FK_PREFERENCE_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: PRODUCT FK_PRODUCT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT"
    ADD CONSTRAINT "FK_PRODUCT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PRODUCT_KEY FK_PRODUCT_KEY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT "FK_PRODUCT_KEY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: PRODUCT_KEY FK_PRODUCT_KEY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT "FK_PRODUCT_KEY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PRODUCT_KEY FK_PRODUCT_KEY_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT_KEY"
    ADD CONSTRAINT "FK_PRODUCT_KEY_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: PRODUCT FK_PRODUCT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PRODUCT"
    ADD CONSTRAINT "FK_PRODUCT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: PUBLIC_KEY FK_PUBLIC_KEY_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PUBLIC_KEY"
    ADD CONSTRAINT "FK_PUBLIC_KEY_NODE" FOREIGN KEY ("NODE") REFERENCES public."NODE"("ID");


--
-- Name: RELEASE FK_RELEASE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RELEASE"
    ADD CONSTRAINT "FK_RELEASE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: RELEASE FK_RELEASE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RELEASE"
    ADD CONSTRAINT "FK_RELEASE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: RELEASE FK_RELEASE_PRODUCT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RELEASE"
    ADD CONSTRAINT "FK_RELEASE_PRODUCT" FOREIGN KEY ("PRODUCT") REFERENCES public."PRODUCT"("ID");


--
-- Name: REPORT_RUN FK_REPORT_ACTIVE_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN"
    ADD CONSTRAINT "FK_REPORT_ACTIVE_NODE" FOREIGN KEY ("ACTIVE_NODE") REFERENCES public."NODE"("ID");


--
-- Name: REPORT FK_REPORT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "FK_REPORT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: REPORT FK_REPORT_ENTITY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "FK_REPORT_ENTITY" FOREIGN KEY ("ENTITY") REFERENCES public."ENTITY"("ID");


--
-- Name: REPORT FK_REPORT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "FK_REPORT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: REPORT FK_REPORT_ORDER_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT"
    ADD CONSTRAINT "FK_REPORT_ORDER_BY" FOREIGN KEY ("ORDER_BY") REFERENCES public."ATTRIBUTE"("ID");


--
-- Name: REPORT_RUN FK_REPORT_REPORT_RUN; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN"
    ADD CONSTRAINT "FK_REPORT_REPORT_RUN" FOREIGN KEY ("REPORT") REFERENCES public."REPORT"("ID");


--
-- Name: REPORT_RUN FK_REPORT_RUN_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN"
    ADD CONSTRAINT "FK_REPORT_RUN_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: REPORT_RUN FK_REPORT_RUN_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."REPORT_RUN"
    ADD CONSTRAINT "FK_REPORT_RUN_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ROLE FK_ROLE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROLE"
    ADD CONSTRAINT "FK_ROLE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: ROLE FK_ROLE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROLE"
    ADD CONSTRAINT "FK_ROLE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: ROSS_PLATFORM_TARGET FK_ROSS_PLATFORM_TARGET_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ROSS_PLATFORM_TARGET"
    ADD CONSTRAINT "FK_ROSS_PLATFORM_TARGET_ID" FOREIGN KEY ("ID") REFERENCES public."TARGET"("ID");


--
-- Name: SDPE_AVAILABLE_MODES FK_SDPE_AVAILABLE_MODES_TARGET_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SDPE_AVAILABLE_MODES"
    ADD CONSTRAINT "FK_SDPE_AVAILABLE_MODES_TARGET_ID" FOREIGN KEY ("TARGET_ID") REFERENCES public."ROSS_PLATFORM_TARGET"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY FK_SNAPSHOT_HISTORY_SOURCE_TARGET; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "FK_SNAPSHOT_HISTORY_SOURCE_TARGET" FOREIGN KEY ("SOURCE_TARGET_ID") REFERENCES public."TARGET"("ID");


--
-- Name: CONFIGURATION_SNAPSHOT_HISTORY FK_SNAPSHOT_HISTORY_TARGET; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CONFIGURATION_SNAPSHOT_HISTORY"
    ADD CONSTRAINT "FK_SNAPSHOT_HISTORY_TARGET" FOREIGN KEY ("TARGET_ID") REFERENCES public."TARGET"("ID");


--
-- Name: SYNCTHING_DEVICE FK_SYNCTHING_DEVICE_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SYNCTHING_DEVICE"
    ADD CONSTRAINT "FK_SYNCTHING_DEVICE_NODE" FOREIGN KEY ("NODE_ID") REFERENCES public."NODE"("ID");


--
-- Name: TARGET_CONFIGURATION_SNAPSHOT FK_TARGET_CONFIGURATION_SNAPSHOT_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_TARGET_CONFIGURATION_SNAPSHOT_ID" FOREIGN KEY ("ID") REFERENCES public."CONFIGURATION_SNAPSHOT"("ID");


--
-- Name: TARGET_CONFIGURATION_SNAPSHOT FK_TARGET_CONFIGURATION_SNAPSHOT_TARGET; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET_CONFIGURATION_SNAPSHOT"
    ADD CONSTRAINT "FK_TARGET_CONFIGURATION_SNAPSHOT_TARGET" FOREIGN KEY ("TARGET_ID") REFERENCES public."TARGET"("ID");


--
-- Name: TARGET FK_TARGET_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "FK_TARGET_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: TARGET FK_TARGET_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "FK_TARGET_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: TARGET FK_TARGET_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "FK_TARGET_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: TARGET FK_TARGET_REMOTE_KEY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "FK_TARGET_REMOTE_KEY" FOREIGN KEY ("REMOTE_KEY") REFERENCES public."REMOTE_KEY"("ID");


--
-- Name: TARGET FK_TARGET_TARGET_GROUP; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TARGET"
    ADD CONSTRAINT "FK_TARGET_TARGET_GROUP" FOREIGN KEY ("TARGET_GROUP") REFERENCES public."TARGET_GROUP"("ID");


--
-- Name: USER FK_USER_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER"
    ADD CONSTRAINT "FK_USER_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: USER FK_USER_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER"
    ADD CONSTRAINT "FK_USER_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: USER_ROLE FK_USER_ROLE_ROLE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_ROLE"
    ADD CONSTRAINT "FK_USER_ROLE_ROLE" FOREIGN KEY ("ROLE") REFERENCES public."ROLE"("ID");


--
-- Name: USER_ROLE FK_USER_ROLE_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_ROLE"
    ADD CONSTRAINT "FK_USER_ROLE_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: USER_SESSION FK_USER_SESSION_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "FK_USER_SESSION_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: USER_SESSION FK_USER_SESSION_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "FK_USER_SESSION_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: USER_SESSION FK_USER_SESSION_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "FK_USER_SESSION_NODE" FOREIGN KEY ("NODE") REFERENCES public."NODE"("ID");


--
-- Name: USER_SESSION FK_USER_SESSION_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION"
    ADD CONSTRAINT "FK_USER_SESSION_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: USER_WATERMARK_MONITOR FK_USER_WATERMARK_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_WATERMARK_MONITOR"
    ADD CONSTRAINT "FK_USER_WATERMARK_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: USER_WATERMARK_MONITOR FK_USER_WATERMARK_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_WATERMARK_MONITOR"
    ADD CONSTRAINT "FK_USER_WATERMARK_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEWPORT FK_VIEWPORT_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "FK_VIEWPORT_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEWPORT FK_VIEWPORT_FOCUSED; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "FK_VIEWPORT_FOCUSED" FOREIGN KEY ("FOCUSED") REFERENCES public."VIEW"("ID");


--
-- Name: VIEWPORT FK_VIEWPORT_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "FK_VIEWPORT_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEWPORT FK_VIEWPORT_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "FK_VIEWPORT_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: VIEWPORT FK_VIEWPORT_WORKSPACE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEWPORT"
    ADD CONSTRAINT "FK_VIEWPORT_WORKSPACE" FOREIGN KEY ("WORKSPACE") REFERENCES public."WORKSPACE"("ID");


--
-- Name: VIEW FK_VIEW_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW"
    ADD CONSTRAINT "FK_VIEW_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEW FK_VIEW_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW"
    ADD CONSTRAINT "FK_VIEW_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEW_PROPERTY FK_VIEW_PROPERTY_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW_PROPERTY"
    ADD CONSTRAINT "FK_VIEW_PROPERTY_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEW_PROPERTY FK_VIEW_PROPERTY_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW_PROPERTY"
    ADD CONSTRAINT "FK_VIEW_PROPERTY_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIEW FK_VIEW_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW"
    ADD CONSTRAINT "FK_VIEW_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: VIEW FK_VIEW_VIEWPORT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIEW"
    ADD CONSTRAINT "FK_VIEW_VIEWPORT" FOREIGN KEY ("VIEWPORT") REFERENCES public."VIEWPORT"("ID");


--
-- Name: VIRTUAL_DIRECTORY FK_VIRTUAL_DIRECTORY_CREATED_B; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY"
    ADD CONSTRAINT "FK_VIRTUAL_DIRECTORY_CREATED_B" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIRTUAL_DIRECTORY FK_VIRTUAL_DIRECTORY_MODIFIED_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY"
    ADD CONSTRAINT "FK_VIRTUAL_DIRECTORY_MODIFIED_" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VIRTUAL_DIRECTORY FK_VIRTUAL_DIRECTORY_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VIRTUAL_DIRECTORY"
    ADD CONSTRAINT "FK_VIRTUAL_DIRECTORY_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB FK_VISUAL_WORKFLOW_JOB_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB FK_VISUAL_WORKFLOW_JOB_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB FK_VISUAL_WORKFLOW_JOB_PARENT; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_PARENT" FOREIGN KEY ("PARENT") REFERENCES public."VIRTUAL_DIRECTORY"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB_RUN FK_VISUAL_WORKFLOW_JOB_RUN_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_RUN_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB_RUN FK_VISUAL_WORKFLOW_JOB_RUN_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_RUN_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB_RUN FK_VISUAL_WORKFLOW_JOB_RUN_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_RUN_NODE" FOREIGN KEY ("NODE") REFERENCES public."NODE"("ID");


--
-- Name: VISUAL_WORKFLOW_JOB_RUN FK_VISUAL_WORKFLOW_JOB_VISUAL_WORKFLOW_JOB_RUN; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_JOB_RUN"
    ADD CONSTRAINT "FK_VISUAL_WORKFLOW_JOB_VISUAL_WORKFLOW_JOB_RUN" FOREIGN KEY ("JOB") REFERENCES public."VISUAL_WORKFLOW_JOB"("ID");


--
-- Name: VMWARE_TARGET FK_VMWARE_TARGET_ID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VMWARE_TARGET"
    ADD CONSTRAINT "FK_VMWARE_TARGET_ID" FOREIGN KEY ("ID") REFERENCES public."TARGET"("ID");


--
-- Name: VISUAL_WORKFLOW_NODE FK_VWF_NODE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE"
    ADD CONSTRAINT "FK_VWF_NODE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_NODE FK_VWF_NODE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE"
    ADD CONSTRAINT "FK_VWF_NODE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_NODE FK_VWF_NODE_VWF_JOB; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_NODE"
    ADD CONSTRAINT "FK_VWF_NODE_VWF_JOB" FOREIGN KEY ("JOB") REFERENCES public."VISUAL_WORKFLOW_JOB"("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET_CONNECTION FK_VWF_SOCKET_CONNECTION_DESTINATION; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET_CONNECTION"
    ADD CONSTRAINT "FK_VWF_SOCKET_CONNECTION_DESTINATION" FOREIGN KEY ("DESTINATION") REFERENCES public."VISUAL_WORKFLOW_SOCKET"("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET_CONNECTION FK_VWF_SOCKET_CONNECTION_SOURCE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET_CONNECTION"
    ADD CONSTRAINT "FK_VWF_SOCKET_CONNECTION_SOURCE" FOREIGN KEY ("SOURCE") REFERENCES public."VISUAL_WORKFLOW_SOCKET"("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET FK_VWF_SOCKET_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET"
    ADD CONSTRAINT "FK_VWF_SOCKET_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET FK_VWF_SOCKET_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET"
    ADD CONSTRAINT "FK_VWF_SOCKET_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: VISUAL_WORKFLOW_SOCKET FK_VWF_SOCKET_VWF_NODE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."VISUAL_WORKFLOW_SOCKET"
    ADD CONSTRAINT "FK_VWF_SOCKET_VWF_NODE" FOREIGN KEY ("NODE") REFERENCES public."VISUAL_WORKFLOW_NODE"("ID");


--
-- Name: WORKSPACE FK_WORKSPACE_CREATED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE"
    ADD CONSTRAINT "FK_WORKSPACE_CREATED_BY" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: WORKSPACE FK_WORKSPACE_MODIFIED_BY; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE"
    ADD CONSTRAINT "FK_WORKSPACE_MODIFIED_BY" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: WORKSPACE FK_WORKSPACE_PERSPECTIVE; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE"
    ADD CONSTRAINT "FK_WORKSPACE_PERSPECTIVE" FOREIGN KEY ("PERSPECTIVE") REFERENCES public."PERSPECTIVE"("ID");


--
-- Name: WORKSPACE FK_WORKSPACE_USER; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."WORKSPACE"
    ADD CONSTRAINT "FK_WORKSPACE_USER" FOREIGN KEY ("USER") REFERENCES public."USER"("ID");


--
-- Name: LICENSE FKb7ldo22wqwrgfvb8uj103sq9d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE"
    ADD CONSTRAINT "FKb7ldo22wqwrgfvb8uj103sq9d" FOREIGN KEY ("MODIFIED_BY") REFERENCES public."USER"("ID");


--
-- Name: MAIL_RECIPIENT FKelhg6ot06j3a639yqisme4t1e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MAIL_RECIPIENT"
    ADD CONSTRAINT "FKelhg6ot06j3a639yqisme4t1e" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: LICENSE FKey4urrgr05umh3djm760idkdr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE"
    ADD CONSTRAINT "FKey4urrgr05umh3djm760idkdr" FOREIGN KEY ("FEATURE") REFERENCES public."FEATURE"("ID");


--
-- Name: LICENSE FKgf39nrn9jsm4vuek1p2ih6m6h; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE"
    ADD CONSTRAINT "FKgf39nrn9jsm4vuek1p2ih6m6h" FOREIGN KEY ("CREATED_BY") REFERENCES public."USER"("ID");


--
-- Name: LICENSE FKjslduh7b46d8jk5lx5yxdq0n2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LICENSE"
    ADD CONSTRAINT "FKjslduh7b46d8jk5lx5yxdq0n2" FOREIGN KEY ("PRODUCT_KEY") REFERENCES public."PRODUCT_KEY"("ID");


--
-- Name: USER_SESSION_SAML_SESSION_INDEX FKq7l00px2fl1ibi1p1guahxxas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."USER_SESSION_SAML_SESSION_INDEX"
    ADD CONSTRAINT "FKq7l00px2fl1ibi1p1guahxxas" FOREIGN KEY ("USER_SESSION_ID") REFERENCES public."USER_SESSION"("ID");


--
-- PostgreSQL database dump complete
--