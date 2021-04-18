
require 'midi-smtp-server'
require 'bootstrap-email'
require 'net/smtp'
require 'mail'

# check setting for smtp relay host
raise 'Missing env BOOTSTRAP_EMAIL_RELAY_HOST setting for startup!' if ENV['BOOTSTRAP_EMAIL_RELAY_HOST'].to_s.empty?

Mail.defaults do
  delivery_method :smtp,
  address: ENV['BOOTSTRAP_EMAIL_RELAY_HOST'],
  port: (ENV['BOOTSTRAP_EMAIL_RELAY_PORT'].to_s.empty? ? 25 : ENV['BOOTSTRAP_EMAIL_RELAY_PORT'].to_i),
  user_name: ENV['BOOTSTRAP_EMAIL_RELAY_USERNAME'].to_s.empty? ? nil : ENV['BOOTSTRAP_EMAIL_RELAY_USERNAME'].to_s,
  password: ENV['BOOTSTRAP_EMAIL_RELAY_PASSWORD'].to_s.empty? ? nil : ENV['BOOTSTRAP_EMAIL_RELAY_PASSWORD'].to_s,
  ssl: ENV['BOOTSTRAP_EMAIL_RELAY_SSL'].to_s.empty? ? false : ENV['BOOTSTRAP_EMAIL_RELAY_SSL'].to_s.downcase == "true",
  tls: ENV['BOOTSTRAP_EMAIL_RELAY_TLS'].to_s.empty? ? false : ENV['BOOTSTRAP_EMAIL_RELAY_TLS'].to_s.downcase == "true"
end

# Permit logging to stdout in Docker containers
$stdout = IO.new(IO.sysopen("/proc/1/fd/1", "w"),"w")
$stdout.sync = true
STDOUT = $stdout

class BootstrapSmtpServer < MidiSmtpServer::Smtpd

  # get each message after DATA <message> .
  def on_message_data_event(ctx)
    logger.info("mail reveived at: [#{ctx[:server][:local_ip]}:#{ctx[:server][:local_port]}] from: [#{ctx[:envelope][:from]}] for recipient(s): [#{ctx[:envelope][:to]}]...")

    # Just decode message ones to make sure, that this message is usable
    mail = Mail.read_from_string(ctx[:message][:data])
    # logger.debug(ctx[:message][:data])

    compile_bootstrap(mail)
    mail.deliver

    logger.debug('message was pushed to smtp')
  end

  def compile_bootstrap(part)
    logger.debug("part is multipart? #{part.multipart?}")
    logger.debug("part is content_type? #{part.content_type}")
    if part.multipart?
      part.parts.each do |a_part|
        compile_bootstrap(a_part)
      end
    else
      if part.content_type.start_with?('text/html')
        logger.debug('processing compilation')
        part.content_type = 'text/html; charset=utf-8'
        part.body = BootstrapEmail::Compiler.new(part.decoded).perform_full_compile
      end
    end
  end

  # event when beginning with message DATA
  def on_message_data_start_event(ctx)
    ctx[:message][:data] <<
      "Received: " <<
      "from #{ctx[:server][:remote_host]} (#{ctx[:server][:remote_ip]}) " <<
      "by #{ctx[:server][:local_host]} (#{ctx[:server][:local_ip]}) " <<
      "with BootstrapSmtpServer Server; " <<
      Time.now.strftime("%a, %d %b %Y %H:%M:%S %z") <<
      ctx[:message][:crlf]
  end

    # event when headers are received while receiving message DATA
  def on_message_data_headers_event(ctx)
    ctx[:message][:data] << 'X-BootstrapSmtpServer: 1.0' << ctx[:message][:crlf]
  end

end

# Create a new server instance for listening
# If no ENV settings use default interfaces 127.0.0.1:2525
# Attention: 127.0.0.1 is not accessible in Docker container even when ports are exposed
server = BootstrapSmtpServer.new(
  hosts: ENV['BOOTSTRAP_EMAIL_GW_HOSTS'] || MidiSmtpServer::DEFAULT_SMTPD_HOST,
  ports: ENV['BOOTSTRAP_EMAIL_GW_PORTS'] || MidiSmtpServer::DEFAULT_SMTPD_PORT,
  max_processings: ENV['BOOTSTRAP_EMAIL_GW_MAX_PROCESSINGS'].to_s.empty? ? MidiSmtpServer::DEFAULT_SMTPD_MAX_PROCESSINGS : ENV['BOOTSTRAP_EMAIL_GW_MAX_PROCESSINGS'].to_i,
  max_connections: ENV['BOOTSTRAP_EMAIL_GW_MAX_CONNECTIONS'].to_s.empty? ? nil : ENV['BOOTSTRAP_EMAIL_GW_MAX_CONNECTIONS'].to_i,
  auth_mode: :AUTH_OPTIONAL,
  tls_mode: :TLS_FORBIDDEN,
  internationalization_extensions:  ENV['BOOTSTRAP_EMAIL_GW_INTERNATIONALIZATION'].to_s.empty? ? nil : ENV['BOOTSTRAP_EMAIL_GW_INTERNATIONALIZATION'].to_s.downcase == "true",
  logger_severity: ENV['BOOTSTRAP_EMAIL_GW_DEBUG'].to_s.empty? ? Logger::INFO : Logger::DEBUG
)

# save flag for Ctrl-C pressed
flag_status_ctrl_c_pressed = false

# try to gracefully shutdown on Ctrl-C
trap('INT') do
  # print an empty line right after ^C
  puts
  # notify flag about Ctrl-C was pressed
  flag_status_ctrl_c_pressed = true
  # signal exit to app
  exit 0
end

# Output for debug
server.logger.info("Starting BootstrapSmtpServer [#{MidiSmtpServer::VERSION::STRING}|#{MidiSmtpServer::VERSION::DATE}]…")

# setup exit code
at_exit do
  # check to shutdown connection
  if server
    # Output for debug
    server.logger.info('Ctrl-C interrupted, exit now...') if flag_status_ctrl_c_pressed
    # info about shutdown
    server.logger.info('Shutdown BootstrapSmtpServer...')
    # stop all threads and connections gracefully
    server.stop
  end
  # Output for debug
  server.logger.info('BootstrapSmtpServer down!')
end

# Start the server
server.start

# Run on server forever
server.join
