SELECT 'CREATE DATABASE platform_manager
  LOCALE_PROVIDER = icu
  ICU_LOCALE = ''und''
  ENCODING = ''UTF8''
  TEMPLATE = template0'
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = 'platform_manager'
)\gexec