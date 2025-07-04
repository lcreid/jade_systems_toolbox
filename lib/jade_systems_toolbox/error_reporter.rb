module JadeSystemsToolbox
  class ErrorReporter < Thor
    class << self
      def report(exception)
        $stderr.puts exception.message

        # TODO: Only show the backtrace back to the user's code (not Thor invocation frames).
        $stderr.puts exception.backtrace if !exception.respond_to?(:verbose) || exception.verbose
      end
    end
  end
end
