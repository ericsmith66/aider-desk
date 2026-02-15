# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'logger'
require 'base64'

module AiderDesk
  # Lightweight response wrapper for all API calls.
  class Response
    attr_reader :status, :body, :error

    def initialize(status:, body: nil, error: nil)
      @status = status
      @body   = body
      @error  = error
      @data   = nil
      @parsed = false
    end

    def success?
      status.between?(200, 299) && error.nil?
    end

    def data
      return @data if @parsed

      @parsed = true
      @data = begin
        JSON.parse(@body) if @body && !@body.empty?
      rescue JSON::ParserError
        nil
      end
    end

    def to_s
      if error
        "Response(#{status}, error=#{error})"
      else
        "Response(#{status})"
      end
    end
  end

  # Raised when +raise_on_error+ is enabled and an API call fails.
  class ApiError < StandardError
    attr_reader :response

    def initialize(message, response)
      @response = response
      super(message)
    end
  end

  # Full-featured HTTP client for the AiderDesk REST API.
  #
  # All methods return an +AiderDesk::Response+ unless noted otherwise.
  class Client
    DEFAULT_BASE_URL     = 'http://localhost:24337'
    DEFAULT_READ_TIMEOUT = 300
    DEFAULT_OPEN_TIMEOUT = 30

    attr_reader :base_url, :project_dir

    def initialize(
      base_url:       nil,
      username:       nil,
      password:       nil,
      project_dir:    nil,
      logger:         nil,
      raise_on_error: false,
      read_timeout:   nil,
      open_timeout:   nil
    )
      @base_url       = base_url    || ENV['AIDER_BASE_URL']    || DEFAULT_BASE_URL
      @username       = username    || ENV['AIDER_USERNAME']
      @password       = password    || ENV['AIDER_PASSWORD']
      @project_dir    = project_dir || ENV['AIDER_PROJECT_DIR']
      @raise_on_error = raise_on_error
      @read_timeout   = read_timeout || DEFAULT_READ_TIMEOUT
      @open_timeout   = open_timeout || DEFAULT_OPEN_TIMEOUT

      @logger = logger || begin
        l = Logger.new($stdout)
        l.level = Logger::WARN
        l
      end
    end

    # ── System ──────────────────────────────────────────────────────────

    def get_env_var(key:, base_dir: nil)
      params = { key: key }
      params[:baseDir] = base_dir if base_dir
      get('/api/system/env-var', params)
    end

    # ── Settings ────────────────────────────────────────────────────────

    def get_settings
      get('/api/settings')
    end

    def update_settings(settings)
      post('/api/settings', settings)
    end

    def get_recent_projects
      get('/api/settings/recent-projects')
    end

    def add_recent_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/settings/add-recent-project', { projectDir: dir })
    end

    def remove_recent_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/settings/remove-recent-project', { projectDir: dir })
    end

    def set_zoom(level:)
      post('/api/settings/zoom', { level: level })
    end

    def get_versions(force_refresh: false)
      params = {}
      params[:forceRefresh] = 'true' if force_refresh
      get('/api/versions', params)
    end

    def download_latest
      post('/api/download-latest', {})
    end

    def get_release_notes
      get('/api/release-notes')
    end

    def clear_release_notes
      post('/api/clear-release-notes', {})
    end

    def get_os
      get('/api/os')
    end

    # ── Prompts ─────────────────────────────────────────────────────────

    def run_prompt(task_id:, prompt:, mode: 'agent', project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/run-prompt', {
        projectDir: dir,
        taskId:     task_id,
        prompt:     prompt,
        mode:       mode
      })
    end

    def save_prompt(task_id:, prompt:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/save-prompt', {
        projectDir: dir,
        taskId:     task_id,
        prompt:     prompt
      })
    end

    # ── Context Files ───────────────────────────────────────────────────

    def add_context_file(task_id:, path:, read_only: false, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/add-context-file', {
        projectDir: dir,
        taskId:     task_id,
        path:       path,
        readOnly:   read_only
      })
    end

    def drop_context_file(task_id:, path:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/drop-context-file', {
        projectDir: dir,
        taskId:     task_id,
        path:       path
      })
    end

    def get_context_files(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/get-context-files', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def get_addable_files(task_id:, search_regex: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id }
      body[:searchRegex] = search_regex if search_regex
      post('/api/get-addable-files', body)
    end

    def get_all_files(task_id:, use_git: false, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/get-all-files', {
        projectDir: dir,
        taskId:     task_id,
        useGit:     use_git
      })
    end

    # ── Custom Commands ─────────────────────────────────────────────────

    def get_custom_commands(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      get('/api/project/custom-commands', { projectDir: dir })
    end

    def run_custom_command(task_id:, command_name:, args: [], mode: 'agent', project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/custom-commands', {
        projectDir:  dir,
        taskId:      task_id,
        commandName: command_name,
        args:        args,
        mode:        mode
      })
    end

    # ── Projects ────────────────────────────────────────────────────────

    def get_projects
      get('/api/projects')
    end

    def add_open_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/add-open', { projectDir: dir })
    end

    def remove_open_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/remove-open', { projectDir: dir })
    end

    def set_active_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/set-active', { projectDir: dir })
    end

    def start_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/start', { projectDir: dir })
    end

    def stop_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/stop', { projectDir: dir })
    end

    def restart_project(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/restart', { projectDir: dir })
    end

    def get_project_settings(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      get('/api/project/settings', { projectDir: dir })
    end

    def update_project_settings(settings = {}, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      patch('/api/project/settings', { projectDir: dir }.merge(settings))
    end

    def update_project_order(project_dirs:)
      post('/api/project/update-order', { projectDirs: project_dirs })
    end

    def get_input_history(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      get('/api/project/input-history', { projectDir: dir })
    end

    def validate_path(path:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/validate-path', { projectDir: dir, path: path })
    end

    def is_project_path(path:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/is-project-path', { projectDir: dir, path: path })
    end

    def file_suggestions(current_path:, directories_only: false, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/file-suggestions', {
        projectDir:      dir,
        currentPath:     current_path,
        directoriesOnly: directories_only
      })
    end

    def paste_image(task_id:, base64_image_data: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id }
      body[:base64ImageData] = base64_image_data if base64_image_data
      post('/api/project/paste-image', body)
    end

    def apply_edits(task_id:, edits:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/apply-edits', {
        projectDir: dir,
        taskId:     task_id,
        edits:      edits
      })
    end

    def run_command(task_id:, command:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/run-command', {
        projectDir: dir,
        taskId:     task_id,
        command:    command
      })
    end

    def init_rules(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/init-rules', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def scrape_web(task_id:, url:, file_path: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id, url: url }
      body[:filePath] = file_path if file_path
      post('/api/project/scrape-web', body)
    end

    # ── Tasks ───────────────────────────────────────────────────────────

    def create_task(name: nil, parent_id: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir }
      body[:name]     = name      if name
      body[:parentId] = parent_id if parent_id
      post('/api/project/tasks/new', body)
    end

    def update_task(task_id:, updates:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks', {
        projectDir: dir,
        id:         task_id,
        updates:    updates
      })
    end

    def load_task(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/load', {
        projectDir: dir,
        id:         task_id
      })
    end

    def list_tasks(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      get('/api/project/tasks', { projectDir: dir })
    end

    def delete_task(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/delete', {
        projectDir: dir,
        id:         task_id
      })
    end

    def duplicate_task(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/duplicate', {
        projectDir: dir,
        id:         task_id
      })
    end

    def fork_task(task_id:, message_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/fork', {
        projectDir: dir,
        taskId:     task_id,
        messageId:  message_id
      })
    end

    def reset_task(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/reset', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def export_task_markdown(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/tasks/export-markdown', {
        projectDir: dir,
        id:         task_id
      })
    end

    def resume_task(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/resume-task', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    # ── Messages ────────────────────────────────────────────────────────

    def remove_last_message(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/remove-last-message', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def remove_message(task_id:, message_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      delete('/api/project/remove-message', {
        projectDir: dir,
        taskId:     task_id,
        messageId:  message_id
      })
    end

    def remove_messages_up_to(task_id:, message_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      delete('/api/project/remove-messages-up-to', {
        projectDir: dir,
        taskId:     task_id,
        messageId:  message_id
      })
    end

    # ── Conversation ────────────────────────────────────────────────────

    def redo_prompt(task_id:, mode:, updated_prompt: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id, mode: mode }
      body[:updatedPrompt] = updated_prompt if updated_prompt
      post('/api/project/redo-prompt', body)
    end

    def compact_conversation(task_id:, mode:, custom_instructions: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id, mode: mode }
      body[:customInstructions] = custom_instructions if custom_instructions
      post('/api/project/compact-conversation', body)
    end

    def handoff_conversation(task_id:, focus: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id }
      body[:focus] = focus if focus
      post('/api/project/handoff-conversation', body)
    end

    def interrupt(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/interrupt', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def clear_context(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/clear-context', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def answer_question(task_id:, answer:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/answer-question', {
        projectDir: dir,
        taskId:     task_id,
        answer:     answer
      })
    end

    # ── Model Settings ──────────────────────────────────────────────────

    def set_main_model(task_id:, main_model:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/settings/main-model', {
        projectDir: dir,
        taskId:     task_id,
        mainModel:  main_model
      })
    end

    def set_weak_model(task_id:, weak_model:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/settings/weak-model', {
        projectDir: dir,
        taskId:     task_id,
        weakModel:  weak_model
      })
    end

    def set_architect_model(task_id:, architect_model:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/settings/architect-model', {
        projectDir:     dir,
        taskId:         task_id,
        architectModel: architect_model
      })
    end

    def set_edit_formats(edit_formats:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/settings/edit-formats', {
        projectDir:  dir,
        editFormats: edit_formats
      })
    end

    # ── Worktrees ───────────────────────────────────────────────────────

    def worktree_merge_to_main(task_id:, squash: true, target_branch: nil, commit_message: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id, squash: squash }
      body[:targetBranch]  = target_branch  if target_branch
      body[:commitMessage] = commit_message if commit_message
      post('/api/project/worktree/merge-to-main', body)
    end

    def worktree_apply_uncommitted(task_id:, target_branch: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id }
      body[:targetBranch] = target_branch if target_branch
      post('/api/project/worktree/apply-uncommitted', body)
    end

    def worktree_revert_last_merge(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/worktree/revert-last-merge', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def worktree_branches(project_dir: nil)
      dir = resolve_project_dir(project_dir)
      get('/api/project/worktree/branches', { projectDir: dir })
    end

    def worktree_status(task_id:, target_branch: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      params = { projectDir: dir, taskId: task_id }
      params[:targetBranch] = target_branch if target_branch
      get('/api/project/worktree/status', params)
    end

    def worktree_rebase_from_branch(task_id:, from_branch: nil, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      body = { projectDir: dir, taskId: task_id }
      body[:fromBranch] = from_branch if from_branch
      post('/api/project/worktree/rebase-from-branch', body)
    end

    def worktree_abort_rebase(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/worktree/abort-rebase', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def worktree_continue_rebase(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/worktree/continue-rebase', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    def worktree_resolve_conflicts(task_id:, project_dir: nil)
      dir = resolve_project_dir(project_dir)
      post('/api/project/worktree/resolve-conflicts-with-agent', {
        projectDir: dir,
        taskId:     task_id
      })
    end

    # ── Convenience Methods ─────────────────────────────────────────────

    # Returns +true+ if the server is reachable and responding, +false+ otherwise.
    def health_check
      res = get_settings
      res.success?
    rescue StandardError
      false
    end

    # Sends a prompt and polls +load_task+ until a +response-completed+ message
    # is detected or the timeout is reached. Yields each new message to the
    # optional block.
    #
    # Returns the final +AiderDesk::Response+ from +load_task+.
    def run_prompt_and_wait(task_id:, prompt:, mode: 'agent', timeout: 120, poll_interval: 5, project_dir: nil, &block)
      run_prompt(task_id: task_id, prompt: prompt, mode: mode, project_dir: project_dir)

      seen_ids  = {}
      deadline  = Time.now + timeout
      last_resp = nil

      loop do
        break if Time.now > deadline

        last_resp = load_task(task_id: task_id, project_dir: project_dir)

        if last_resp.success? && last_resp.data
          messages = last_resp.data.fetch('messages', [])
          completed = false

          messages.each do |msg|
            msg_id = msg['id'] || msg.object_id.to_s
            next if seen_ids.key?(msg_id)

            seen_ids[msg_id] = true
            block&.call(msg)
            completed = true if msg['type'] == 'response-completed'
          end

          break if completed
        end

        sleep(poll_interval)
      end

      last_resp || Response.new(status: 0, error: 'Timed out waiting for response')
    end

    # One-shot: creates a new task, runs a prompt on it, and waits for
    # completion.
    #
    # Returns a hash with keys +:task_id+, +:response+, +:messages+.
    def create_task_and_run(prompt:, name: nil, mode: 'code', timeout: 120, poll_interval: 5, project_dir: nil, &block)
      task_res = create_task(name: name, project_dir: project_dir)
      task_id  = task_res.data&.fetch('id', nil)

      unless task_id
        return {
          task_id:  nil,
          response: task_res,
          messages: []
        }
      end

      collected = []
      response = run_prompt_and_wait(
        task_id:       task_id,
        prompt:        prompt,
        mode:          mode,
        timeout:       timeout,
        poll_interval: poll_interval,
        project_dir:   project_dir
      ) do |msg|
        collected << msg
        block&.call(msg)
      end

      {
        task_id:  task_id,
        response: response,
        messages: collected
      }
    end

    private

    # Resolves the project directory from the per-call argument, falling back
    # to the client-level default. Raises +ArgumentError+ if neither is set.
    def resolve_project_dir(override)
      dir = override || @project_dir
      raise ArgumentError, 'project_dir is required — set it at client init or pass it per-call' unless dir

      dir
    end

    # ── HTTP helpers ────────────────────────────────────────────────────

    def get(path, params = {})
      uri = build_uri(path, params)
      req = Net::HTTP::Get.new(uri)
      execute(uri, req)
    end

    def post(path, body = {})
      uri = build_uri(path)
      req = Net::HTTP::Post.new(uri)
      req.body = JSON.generate(body)
      req['Content-Type'] = 'application/json'
      execute(uri, req)
    end

    def patch(path, body = {})
      uri = build_uri(path)
      req = Net::HTTP::Patch.new(uri)
      req.body = JSON.generate(body)
      req['Content-Type'] = 'application/json'
      execute(uri, req)
    end

    def delete(path, body = {})
      uri = build_uri(path)
      req = Net::HTTP::Delete.new(uri)
      req.body = JSON.generate(body)
      req['Content-Type'] = 'application/json'
      execute(uri, req)
    end

    def build_uri(path, params = {})
      uri = URI.join(@base_url, path)
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def execute(uri, request)
      request.basic_auth(@username, @password) if @username

      @logger.debug("#{request.method} #{uri}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = (uri.scheme == 'https')
      http.read_timeout = @read_timeout
      http.open_timeout = @open_timeout

      response = http.request(request)

      @logger.debug("Response #{response.code}: #{response.body&.slice(0, 500)}")

      result = Response.new(status: response.code.to_i, body: response.body)

      maybe_raise(result)
      result
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
           Errno::ETIMEDOUT, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
      @logger.error("Connection failed: #{e.message}")
      result = Response.new(status: 0, error: e.message)
      maybe_raise(result)
      result
    end

    def maybe_raise(response)
      return unless @raise_on_error
      return if response.success?

      raise ApiError.new(
        "API request failed (#{response.status}): #{response.error || response.body}",
        response
      )
    end
  end
end
