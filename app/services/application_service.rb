class ApplicationService
    # Base service class following service object pattern
    # Provides common error handling and logging functionality
    
    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end
    
    protected
    
    def log_error(message, exception = nil)
      Rails.logger.error "[#{self.class.name}] #{message}"
      Rails.logger.error exception.backtrace.join("\n") if exception
    end
    
    def log_info(message)
      Rails.logger.info "[#{self.class.name}] #{message}"
    end
end