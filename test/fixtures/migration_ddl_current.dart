// 自动生成 (tool/gen_migration_fixtures.dart)：勿手改
// current unified_chat DDL, expected schema after migration (src: unified_chat_ddl.dart)
const List<String> kDdlCurrentStatements = [
  r'''
CREATE TABLE suchat_unified_platform_spec (
        id                            TEXT      PRIMARY KEY,
        display_name                  TEXT      NOT NULL,
        host_url                      TEXT      NOT NULL,
        cc_prefix                     TEXT      NOT NULL    DEFAULT '/v1/chat/completions',
        img_gen_prefix                TEXT,
        video_gen_prefix              TEXT,
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
        supports_image_input        INTEGER   NOT NULL    DEFAULT 0,
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
CREATE TABLE IF NOT EXISTS translation_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    source_lang TEXT NOT NULL,
    target_lang TEXT NOT NULL,
    source_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    model_name TEXT,
    platform_name TEXT,
    audio_path TEXT
  );
''',
  r'''
CREATE INDEX IF NOT EXISTS idx_translation_history_created_at
  ON translation_history (created_at DESC);
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
        updated_at                    INTEGER   NOT NULL,
        description                   TEXT,
        personality                   TEXT,
        scenario                      TEXT,
        first_message                 TEXT,
        example_dialogue              TEXT,
        tags                          TEXT,
        preferred_model_id            TEXT,
        background                    TEXT,
        background_opacity            REAL,
        skill_ids                     TEXT
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
        -- 2026-09-09 v4: temperature/max_tokens/top_p/context_message_length
        -- 可空(null=未设置→请求不传该参数/上下文不限制)，去掉NOT NULL
        temperature                 REAL                    DEFAULT 0.7,
        max_tokens                  INTEGER                 DEFAULT 4096,
        top_p                       REAL                    DEFAULT 1.0,
        frequency_penalty           REAL                    DEFAULT 0.0,
        presence_penalty            REAL                    DEFAULT 0.0,
        context_message_length      INTEGER                 DEFAULT 6,
        is_stream                   INTEGER   NOT NULL      DEFAULT 1,
        extra_params                TEXT,
        message_count               INTEGER   NOT NULL      DEFAULT 0,
        total_tokens                INTEGER   NOT NULL      DEFAULT 0,
        total_cost                  REAL      NOT NULL      DEFAULT 0.0,
        is_pinned                   INTEGER   NOT NULL      DEFAULT 0,
        is_archived                 INTEGER   NOT NULL      DEFAULT 0,
        created_at                  INTEGER   NOT NULL,
        updated_at                  INTEGER   NOT NULL,
        current_branch_path         TEXT,
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
        segments            TEXT,
        is_streaming        INTEGER   NOT NULL     DEFAULT 0,
        is_error            INTEGER   NOT NULL     DEFAULT 0,
        error_message       TEXT,
        metadata            TEXT,
        created_at          INTEGER   NOT NULL,
        updated_at          INTEGER   NOT NULL,
        parent_id           TEXT,
        branch_index        INTEGER   NOT NULL     DEFAULT 0,
        depth               INTEGER   NOT NULL     DEFAULT 0,
        branch_path         TEXT      NOT NULL     DEFAULT '',
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
  r'''
CREATE TABLE suchat_unified_mcp_server (
        id            TEXT      PRIMARY KEY,
        name          TEXT      NOT NULL    UNIQUE,
        display_name  TEXT      NOT NULL,
        transport     TEXT      NOT NULL    DEFAULT 'http',
        url           TEXT,
        command       TEXT,
        args          TEXT,
        env           TEXT,
        headers       TEXT,
        enabled       INTEGER   NOT NULL    DEFAULT 1,
        is_built_in   INTEGER   NOT NULL    DEFAULT 0,
        is_search_source INTEGER NOT NULL    DEFAULT 0,
        approval_required INTEGER NOT NULL    DEFAULT 0,
        tools_cache   TEXT,
        oauth_client_id TEXT,
        oauth_scopes  TEXT,
        created_at    INTEGER   NOT NULL,
        updated_at    INTEGER   NOT NULL
      );
''',
  r'''
CREATE TABLE suchat_unified_skill (
        id            TEXT      PRIMARY KEY,
        name          TEXT      NOT NULL    UNIQUE,
        description   TEXT,
        source        TEXT      NOT NULL    DEFAULT 'import',
        source_url    TEXT,
        enabled       INTEGER   NOT NULL    DEFAULT 1,
        dir_path      TEXT      NOT NULL,
        aux_count     INTEGER   NOT NULL    DEFAULT 0,
        file_size     INTEGER   NOT NULL    DEFAULT 0,
        created_at    INTEGER   NOT NULL,
        updated_at    INTEGER   NOT NULL
      );
''',
];
