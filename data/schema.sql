-- Seoul Subway Passengers, PostgreSQL schema

CREATE TABLE IF NOT EXISTS ETL_pipeline_run (
    run_id UUID PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL,
    target_date_from DATE NOT NULL,
    target_date_to DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    extracted_row_count INTEGER NOT NULL DEFAULT 0,
    loaded_row_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,

    CONSTRAINT chk_pipeline_run_status
        CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED'))
);

CREATE TABLE IF NOT EXISTS ETL_api_response (
    response_id BIGSERIAL PRIMARY KEY,
    run_id UUID NOT NULL,
    api_name VARCHAR(100) NOT NULL,
    request_params JSONB NOT NULL DEFAULT '{}'::JSONB,
    page_no INTEGER,
    http_status INTEGER,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    response_body JSONB NOT NULL,

    CONSTRAINT fk_api_response_run
        FOREIGN KEY (run_id)
        REFERENCES etl_pipeline_run (run_id)
);

CREATE TABLE IF NOT EXISTS ETL_station_info (
    station_code VARCHAR(30) NOT NULL,
    line_code VARCHAR(30) NOT NULL,
    station_name VARCHAR(100) NOT NULL,
    line_name VARCHAR(100),
    external_station_code VARCHAR(30),
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (station_code, line_code)
);

CREATE TABLE IF NOT EXISTS ETL_station_passenger (
    service_date DATE NOT NULL,
    station_code VARCHAR(30) NOT NULL,
    line_code VARCHAR(30) NOT NULL,
    time_slot VARCHAR(20) NOT NULL,
    card_type VARCHAR(50) NOT NULL DEFAULT 'ALL',
    board_count INTEGER NOT NULL,
    alight_count INTEGER NOT NULL,
    run_id UUID NOT NULL,
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (
        service_date,
        station_code,
        line_code,
        time_slot,
        card_type
    ),

    CONSTRAINT chk_board_count
        CHECK (board_count >= 0),

    CONSTRAINT chk_alight_count
        CHECK (alight_count >= 0),

    CONSTRAINT fk_passenger_station
        FOREIGN KEY (station_code, line_code)
        REFERENCES ETL_station_info (station_code, line_code),

    CONSTRAINT fk_passenger_run
        FOREIGN KEY (run_id)
        REFERENCES ETL_pipeline_run (run_id)
);

-- Dashboard, analysis queries
CREATE INDEX IF NOT EXISTS idx_station_passenger_station_date
    ON ETL_station_passenger (station_code, line_code, service_date);

CREATE INDEX IF NOT EXISTS idx_station_passenger_date_line
    ON ETL_station_passenger (service_date, line_code);

-- ETL operations, troubleshooting
CREATE INDEX IF NOT EXISTS idx_api_response_run_received
    ON ETL_api_response (run_id, received_at DESC);

CREATE INDEX IF NOT EXISTS idx_pipeline_run_status_started
    ON ETL_pipeline_run (status, started_at DESC);
