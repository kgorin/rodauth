module Rodauth
  Base = Feature.define(:base) do
    auth_value_method :account_id, :id
    auth_value_method :account_open_status_value, 2
    auth_value_method :account_password_hash_column, nil
    auth_value_method :account_status_id, :status_id
    auth_value_method :account_unverified_status_value, 1
    auth_value_method :default_redirect, '/'
    auth_value_method :email_subject_prefix, nil
    auth_value_method :invalid_password_message, "invalid password"
    auth_value_method :login_column, :email
    auth_value_method :password_hash_column, :password_hash
    auth_value_method :password_hash_table, :account_password_hashes
    auth_value_method :no_matching_login_message, "no matching login"
    auth_value_method :login_param, 'login'
    auth_value_method :login_confirm_param, 'login-confirm'
    auth_value_method :login_label, 'Login'
    auth_value_method :password_label, 'Password'
    auth_value_method :logins_do_not_match_message, 'logins do not match'
    auth_value_method :password_param, 'password'
    auth_value_method :password_confirm_param, 'password-confirm'
    auth_value_method :session_key, :account_id
    auth_value_method :passwords_do_not_match_message, 'passwords do not match'
    auth_value_method :password_minimum_length, 6
    auth_value_method :require_login_notice_message, "Please login to continue"
    auth_value_method :prefix, ''
    auth_value_method :require_bcrypt?, true
    auth_value_method :require_mail?, false 
    auth_value_method :same_as_existing_password_message, "invalid password, same as current password"
    auth_value_method :title_instance_variable, nil 

    redirect(:require_login){"#{prefix}/login"}

    auth_value_methods(
      :account_model,
      :email_from,
      :login_confirm_label,
      :password_confirm_label,
      :password_does_not_meet_requirements_message,
      :login_does_not_meet_requirements_message,
      :password_hash_cost,
      :password_too_short_message,
      :require_login_redirect,
      :skip_status_checks?,
      :set_deadline_values?,
      :use_date_arithmetic?,
      :use_database_authentication_functions?
    )

    auth_methods(
      :account_from_login,
      :account_from_session,
      :account_id_value,
      :account_session_value,
      :already_logged_in,
      :authenticated?,
      :clear_session,
      :create_email,
      :csrf_tag,
      :email_to,
      :function_name,
      :logged_in?,
      :login_errors_message,
      :login_meets_requirements?,
      :login_required,
      :open_account?,
      :password_hash,
      :password_match?,
      :password_meets_requirements?,
      :random_key,
      :session_value,
      :set_error_flash,
      :set_notice_flash,
      :set_notice_now_flash,
      :set_password,
      :set_redirect_error_flash,
      :set_title,
      :unverified_account_message,
      :update_session
    )

    attr_reader :scope
    attr_reader :account

    def initialize(scope)
      @scope = scope
    end

    def features
      self.class.features
    end

    def request
      scope.request
    end

    def response
      scope.response
    end

    def session
      scope.session
    end

    def flash
      scope.flash
    end

    # Return a string for the parameter name.  This will be an empty
    # string if the parameter doesn't exist.
    def param(key)
      _param(key).to_s
    end

    # Return a string for the parameter name, or nil if there is no
    # parameter with that name.
    def _param(key)
      value = request.params[key]
      value.to_s if value
    end

    # Overridable methods

    def account_id_value
      account.send(account_id)
    end
    alias account_session_value account_id_value

    def session_value
      session[session_key]
    end

    def account_status_id_value
      account.send(account_status_id)
    end

    def _account_from_login(login)
      @account = account_from_login(login)
    end

    def account_from_login(login)
      ds = account_model.where(login_column=>login)
      ds = ds.where(account_status_id=>[account_unverified_status_value, account_open_status_value]) unless skip_status_checks?
      ds.first
    end

    def open_account?
      skip_status_checks? || account_status_id_value == account_open_status_value 
    end

    def unverified_account_message
      "unverified account, please verify account before logging in"
    end

    def update_session
      clear_session
      session[session_key] = account_session_value
    end

    def check_before(feature)
      meth = :"check_before_#{feature.feature_name}"
      if respond_to?(meth)
        send(meth)
      elsif feature.account_required?
        require_account
      elsif logged_in?
        already_logged_in 
      end
    end

    def account_model
      ::Account
    end

    def db
      account_model.db
    end

    # If the account_password_hash_column is set, the password hash is verified in
    # ruby, it will not use a database function to do so, it will check the password
    # hash using bcrypt.
    def account_password_hash_column
      nil
    end

    def already_logged_in
      nil
    end

    def clear_session
      session.clear
    end

    def login_required
      set_notice_flash require_login_notice_message
      request.redirect require_login_redirect
    end

    def random_key
      if RUBY_VERSION >= '1.9'
        SecureRandom.urlsafe_base64(32)
      else
        # :nocov:
        SecureRandom.hex(32)
        # :nocov:
      end
    end

    def timing_safe_eql?(provided, actual)
      provided = provided.to_s
      provided.ljust(actual.length)
      match = true
      actual.length.times do |i|
        match = false unless provided[i] == actual[i]
      end
      match = false unless provided.length == actual.length
      match
    end

    def set_title(title)
      if title_instance_variable
        scope.instance_variable_set(title_instance_variable, title)
      end
    end

    def set_error_flash(message)
      flash.now[:error] = message
    end

    def set_redirect_error_flash(message)
      flash[:error] = message
    end

    def set_notice_flash(message)
      flash[:notice] = message
    end

    def set_notice_now_flash(message)
      flash.now[:notice] = message
    end

    def logged_in?
      session[session_key]
    end

    def require_login
      login_required unless logged_in?
    end

    def authenticated?
      logged_in?
    end

    def require_authentication
      require_login
    end

    def require_account
      require_authentication
      require_account_session
    end

    def require_account_session
      unless _account_from_session
        clear_session
        login_required
      end
    end

    def login_confirm_label
      "Confirm #{login_label}"
    end

    def password_confirm_label
      "Confirm #{password_label}"
    end

    def login_errors_message
      if errors = account.errors.on(login_column)
        errors.join(', ')
      end
    end

    attr_reader :password_requirement_message

    def password_does_not_meet_requirements_message
      "invalid password, does not meet requirements#{" (#{password_requirement_message})" if password_requirement_message}"
    end

    def password_too_short_message
      "minimum #{password_minimum_length} characters"
    end

    def password_meets_requirements?(password)
      return true if password_minimum_length <= password.length
      @password_requirement_message = password_too_short_message
      false
    end
    
    def login_does_not_meet_requirements_message
      "invalid login, not a valid email address"
    end

    def login_meets_requirements?(login)
      login =~ /\A[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+\z/
    end

    def account_initial_status_value
      account_open_status_value
    end

    def _account_from_session
      @account = account_from_session
    end

    def account_from_session
      ds = account_model.where(account_id=>session_value)
      ds = ds.where(account_status_id=>account_open_status_value) unless skip_status_checks?
      ds.first
    end

    def password_hash_cost
      if ENV['RACK_ENV'] == 'test'
        BCrypt::Engine::MIN_COST
      else
        # :nocov:
        BCrypt::Engine::DEFAULT_COST
        # :nocov:
      end
    end

    def password_hash(password)
      BCrypt::Password.create(password, :cost=>password_hash_cost)
    end

    def set_password(password)
      hash = password_hash(password)
      if account_password_hash_column
        account.set(account_password_hash_column=>hash).save_changes(:raise_on_save_failure=>true)
      elsif db[password_hash_table].where(account_id=>account_id_value).update(password_hash_column=>hash) == 0
        # This shouldn't raise a uniqueness error, as the update should only fail for a new user,
        # and an existing user shouldn't always havae a valid password hash row.  If this does
        # fail, retrying it will cause problems, it will override a concurrently running update
        # with potentially a different password.
        db[password_hash_table].insert(account_id=>account_id_value, password_hash_column=>hash)
      end
      hash
    end

    def csrf_tag
      scope.csrf_tag if scope.respond_to?(:csrf_tag)
    end

    def button(value, opts={})
      opts = {:locals=>{:value=>value, :opts=>opts}}
      opts[:path] = template_path('button')
      scope.render(opts)
    end

    def transaction(opts={}, &block)
      db.transaction(opts, &block)
    end

    def email_from
      "webmaster@#{request.host}"
    end

    def email_to
      account.email
    end

    def create_email(subject, body)
      m = Mail.new
      m.from = email_from
      m.to = email_to
      m.subject = "#{email_subject_prefix}#{subject}"
      m.body = body
      m
    end

    def view(page, title)
      set_title(title)
      _view(:view, page)
    end

    def render(page)
      _view(:render, page)
    end

    def skip_status_checks?
      !account_model.columns.include?(account_status_id)
    end

    def post_configure
      require 'bcrypt' if require_bcrypt?
      require 'mail' if require_mail?
      db.extension :date_arithmetic if use_date_arithmetic?
    end

    def use_date_arithmetic?
      set_deadline_values?
    end

    def set_deadline_values?
      db.database_type == :mysql
    end

    def use_database_authentication_functions?
      case db.database_type
      when :postgres, :mysql, :mssql
        true
      else
        # :nocov:
        false
        # :nocov:
      end
    end

    def function_name(name)
      if db.database_type == :mssql
        # :nocov:
        "dbo.#{name}"
        # :nocov:
      else
        name
      end
    end

    def password_match?(password)
      if account_password_hash_column
        BCrypt::Password.new(account.send(account_password_hash_column)) == password
      elsif use_database_authentication_functions?
        id = account_id_value
        if salt = db.get(Sequel.function(function_name(:rodauth_get_salt), id))
          hash = BCrypt::Engine.hash_secret(password, salt)
          db.get(Sequel.function(function_name(:rodauth_valid_password_hash), id, hash))
        end
      else
        # :nocov:
        hash = db[password_hash_table].
          where(account_id=>account_id_value).
          get(password_hash_column)
        if hash
          BCrypt::Password.new(hash) == password
        end
        # :nocov:
      end
    end

    def template_path(page)
      File.join(File.dirname(__FILE__), '../../../templates', "#{page}.str")
    end

    private

    # This is needed for jdbc/sqlite, which returns timestamp columns as strings
    def convert_timestamp(timestamp)
      timestamp = db.to_application_timestamp(timestamp) if timestamp.is_a?(String)
      timestamp
    end

    # This is used to avoid race conditions when using the pattern of inserting when
    # an update affects no rows.  In such cases, if a row is inserted between the
    # update and the insert, the insert will fail with a uniqueness error, but
    # retrying will work.  It is possible for it to fail again, but only if the row
    # is deleted before the update and readded before the insert, which is very
    # unlikely to happen.  In such cases, raising an exception is acceptable.
    def retry_on_uniqueness_violation(&block)
      if raises_uniqueness_violation?(&block)
        yield
      end
    end

    # In cases where retrying on uniqueness violations cannot work, this will detect
    # whether a uniqueness violation is raised by the block and return the exception if so.
    # This method should be used if you don't care about the exception itself.
    def raises_uniqueness_violation?(&block)
      transaction(:savepoint=>:only, &block)
      false
    rescue Sequel::UniqueConstraintViolation => e
      # :nocov:
      e
      # :nocov:
    end

    # If you would like to operate/reraise the exception, this alias makes more sense.
    alias raised_uniqueness_violation raises_uniqueness_violation?

    # If you just want to ignore uniqueness violations, this alias makes more sense.
    alias ignore_uniqueness_violation raises_uniqueness_violation?

    def set_deadline_value(hash, column, interval)
      if set_deadline_values?
        # :nocov:
        hash[column] = Sequel.date_add(Sequel::CURRENT_TIMESTAMP, interval)
        # :nocov:
      end
    end

    def _view(meth, page)
      auth = self
      scope.instance_exec do
        template_opts = find_template(parse_template_opts(page, :locals=>{:rodauth=>auth}))
        unless File.file?(template_path(template_opts))
          template_opts[:path] = auth.template_path(page)
        end
        send(meth, template_opts)
      end
    end
  end
end
