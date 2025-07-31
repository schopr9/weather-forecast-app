class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  
  protected
  
  # Standardized error handling for enterprise applications
  def handle_api_error(error)
    Rails.logger.error "API Error: #{error.message}"
    flash[:error] = "Unable to retrieve weather data. Please try again later."
    redirect_to root_path
  end
  
  def handle_invalid_address
    flash[:error] = "Please enter a valid address."
    redirect_to root_path
  end
end
