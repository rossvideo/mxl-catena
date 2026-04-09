
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


CREATE SEQUENCE public."OGP_FRAME_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNER TO postgres;

ALTER SEQUENCE public."OGP_FRAME_ID_seq" OWNED BY public."OGP_FRAME"."ID";
ALTER TABLE public."OGP_FRAME"
ALTER COLUMN "ID" SET DEFAULT nextval('public."OGP_FRAME_ID_seq"');
-- 
-- DATA for table "OGP_FRAME"
--

INSERT INTO public."OGP_FRAME"
("NAME","HOSTNAME","PORT","PROTOCOL","USE_SSL","CONNECTION_SETTINGS","CREATED","MODIFIED")
VALUES
('Media IO', 'host.docker.internal', 7248, 'CATENA', false, '<properties></properties>', NOW(), NOW()),
('Catena NDI to MXL Sink', 'host.docker.internal', 7269, 'CATENA', false, '<properties><entry key="node-id">127.0.0.1:7269</entry></properties>', NOW(), NOW()),
('Catena MXL to NDI', 'host.docker.internal', 7254, 'CATENA', false, '<properties><entry key="node-id">127.0.0.1:7254</entry></properties>', NOW(), NOW())
;

--
-- Name: LICENSE_KEY; Type: TABLE; Schema: public; Owner: postgres
--./

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
-- DATA for table "LICENSE_KEY"
--
INSERT INTO public."LICENSE_KEY"
("ID","CREATED","FEATURE_ID","KEY","LICENSED_TO","MODIFIED","REQUEST_CODE","VERSION_ID","CREATED_BY","MODIFIED_BY","NODE")
VALUES
(1,NOW(), '290', 'ZRVW4-WVJKE-FVMWK-G392L', 'Catena', NOW(), '7-GRZPE-QNQ67-MKN39', 1, 2, 1, 1),
(2,NOW(), '210', NULL, NULL, NOW(), '6-VDM70-KSZDR-HG92T', 0, 2, 2, 1),
(3,NOW(), '220', NULL, NULL, NOW(), '9-HTJ37-PN0NB-3CP3J', 0, 2, 2, 1),
(4,NOW(), '240', NULL, NULL, NOW(), '5-CBLPX-T0VJW-HM9CP', 0, 2, 2, 1),
(5,NOW(), '200', 'CN1HS-9NBFZ-X7N4S-GSRLF', 'Catena', NOW(), 'F-J8LMT-15PHV-KHT1P', 1, 2, 1, 1),
(6,NOW(), '1', '3NKWW-91PNY-7E43V-3R7S0', 'Catena', NOW(), 'J-FPB23-3JT6B-WXC7C', 1, 2, 1, 1),
(7,NOW(), '2', 'KK7VB-2F49W-6TLDG-L3K0X', 'Catena', NOW(), '1-GKQQX-YWQYH-YNBB6', 1, 2, 1, 1),
(8,NOW(), '423', '2XK33-5NYT9-0ST4G-N388Z', 'Catena', NOW(), '0-HZN4D-2K8YB-5YE0S', 1, 2, 1, 1),
(9,NOW(), '422', 'V7YEK-TR9TN-ZYMKW-W1BZJ', 'Catena', NOW(), 'M-G5SQ6-1YWPN-MZZBP', 1, 2, 1, 1),
(10,NOW(), '300', 'NZFWP-W6HGE-EPRWW-HPYNX', 'Catena', NOW(), 'R-HZDQF-1M0RD-1VKFX', 1, 2, 1, 1),
(11,NOW(), '310', '2GD53-5SZNF-K1814-550RP', 'Catena', NOW(), '1-YEGMJ-THE48-18K36', 1, 2, 1, 1),
(12,NOW(), '425', 'XV47M-7CJJV-14FNW-6JV6Z', 'Catena', NOW(), '7-SRDXD-2N7D6-MLY25', 1, 2, 1, 1),
(13,NOW(), '424', 'G3SWB-2YGPC-ZBMJX-CF36M', 'Catena', NOW(), 'P-GEDGH-81ETX-80F28', 1, 2, 1, 1),
(14,NOW(), '421', 'GBVP0-G6XXY-PNN3Y-JLGX8', 'Catena', NOW(), 'H-N7B87-QWBNL-F3BFF', 1, 2, 1, 1),
(15,NOW(), '0', '0N173-Q146H-93G7W', 'Catena', NOW(), NULL, 1, 1, 1, NULL)
;


