// 自动生成 (tool/gen_migration_fixtures.dart)：勿手改
// 0.1.4 (commit 748e2ef) unified_chat DDL, v1 start schema (src: ddl_014tag.dart)
const List<String> kDdlV10Statements = [
  r'''
CREATE TABLE suchat_unified_platform_spec (
        id                            TEXT      PRIMARY KEY,
        display_name                  TEXT      NOT NULL,
        host_url                      TEXT      NOT NULL,
        cc_prefix                     TEXT      NOT NULL    DEFAULT '/v1/chat/completions',
        img_gen_prefix                TEXT,
        tts_prefix                    TEXT,
        asr_prefix                    TEXT,
        is_built_in                   INTEGER   NOT NULL    DEFAULT 0,
        is_active                     INTEGER   NOT NULL    DEFAULT 0,
        description                   TEXT,
        extra_params                  TEXT,
        created_at                    INTEGER   NOT NULL,
        updated_at                    INTEGER   NOT NULL
      );
''',
  r'''
CREATE TABLE suchat_unified_model_spec (
        id                          TEXT      PRIMARY KEY,
        platform_id                 TEXT      NOT NULL,
        model_name                  TEXT      NOT NULL,
        display_name                TEXT      NOT NULL,
        model_type                  TEXT      NOT NULL,
        supports_thinking           INTEGER   NOT NULL    DEFAULT 0,
        supports_vision             INTEGER   NOT NULL    DEFAULT 0,
        supports_tool_calling       INTEGER   NOT NULL    DEFAULT 0,
        is_built_in                 INTEGER   NOT NULL    DEFAULT 0,
        is_active                   INTEGER   NOT NULL    DEFAULT 1,
        is_favorite                 INTEGER   NOT NULL    DEFAULT 0,
        description                 TEXT,
        extra_config                TEXT,
        created_at                  INTEGER   NOT NULL,
        updated_at                  INTEGER   NOT NULL,
        FOREIGN KEY (platform_id) REFERENCES suchat_unified_platform_spec (id) ON DELETE CASCADE
      );
''',
  r'''
CREATE TABLE IF NOT EXISTS suchat_unified_chat_partner (
        id                            TEXT      PRIMARY KEY,
        name                          TEXT      NOT NULL,
        prompt                        TEXT      NOT NULL,
        avatar_url                    TEXT,
        is_built_in                   INTEGER   NOT NULL    DEFAULT 0,
        is_active                     INTEGER   NOT NULL    DEFAULT 1,
        is_favorite                   INTEGER   NOT NULL    DEFAULT 0,
        context_message_length        INTEGER               DEFAULT 6,
        temperature                   REAL,
        top_p                         REAL,
        max_tokens                    INTEGER,
        is_stream                     INTEGER               DEFAULT 1,
        created_at                    INTEGER   NOT NULL,
        updated_at                    INTEGER   NOT NULL
      );
''',
  r'''
CREATE TABLE suchat_unified_conversation (
        id                          TEXT      PRIMARY KEY,
        title                       TEXT      NOT NULL,
        model_id                    TEXT      NOT NULL,
        platform_id                 TEXT      NOT NULL,
        partner_id                  TEXT,
        system_prompt               TEXT,
        temperature                 REAL                    DEFAULT 0.7,
        max_tokens                  INTEGER   NOT NULL      DEFAULT 4096,
        top_p                       REAL                    DEFAULT 1.0,
        frequency_penalty           REAL                    DEFAULT 0.0,
        presence_penalty            REAL                    DEFAULT 0.0,
        context_message_length      INTEGER   NOT NULL      DEFAULT 6,
        is_stream                   INTEGER   NOT NULL      DEFAULT 1,
        extra_params                TEXT,
        message_count               INTEGER   NOT NULL      DEFAULT 0,
        total_tokens                INTEGER   NOT NULL      DEFAULT 0,
        total_cost                  REAL      NOT NULL      DEFAULT 0.0,
        is_pinned                   INTEGER   NOT NULL      DEFAULT 0,
        is_archived                 INTEGER   NOT NULL      DEFAULT 0,
        created_at                  INTEGER   NOT NULL,
        updated_at                  INTEGER   NOT NULL,
        FOREIGN KEY (model_id) REFERENCES suchat_unified_model_spec (id),
        FOREIGN KEY (platform_id) REFERENCES suchat_unified_platform_spec (id)
      );
''',
  r'''
CREATE TABLE suchat_unified_chat_message (
        id                  TEXT      PRIMARY KEY,
        conversation_id     TEXT      NOT NULL,
        role                TEXT      NOT NULL     CHECK (role IN ('system', 'user', 'assistant', 'function', 'tool')),
        thinking_content    TEXT,
        thinking_time       INTEGER,
        content             TEXT,
        content_type        TEXT      NOT NULL     DEFAULT 'text',
        multimodal_content  TEXT,
        function_call       TEXT,
        tool_calls          TEXT,
        tool_call_id        TEXT,
        name                TEXT,
        finish_reason       TEXT,
        token_count         INTEGER                DEFAULT 0,
        cost                REAL                   DEFAULT 0.0,
        model_name_used     TEXT,
        platform_id_used    TEXT,
        response_time_ms    INTEGER,
        search_references   TEXT,
        is_streaming        INTEGER   NOT NULL     DEFAULT 0,
        is_error            INTEGER   NOT NULL     DEFAULT 0,
        error_message       TEXT,
        metadata            TEXT,
        created_at          INTEGER   NOT NULL,
        updated_at          INTEGER   NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES suchat_unified_conversation (id) ON DELETE CASCADE
      );
''',
  r'''
CREATE TABLE suchat_unified_api_key (
        id                  TEXT      NOT NULL,
        platform_id         TEXT      NOT NULL,
        key_name            TEXT      NOT NULL,
        is_active           INTEGER   NOT NULL     DEFAULT 1,
        last_used_at        INTEGER,
        usage_count         INTEGER                DEFAULT 0,
        created_at          INTEGER   NOT NULL,
        updated_at          INTEGER   NOT NULL,
        FOREIGN KEY (platform_id) REFERENCES suchat_unified_platform_spec (id) ON DELETE CASCADE
      );
''',
];
