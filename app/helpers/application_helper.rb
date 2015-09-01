module ApplicationHelper
  def check_auth_token
    halt 403 unless Token.exists?(params[:token])
  end

  def is_command?(text)
    text.match(/\//)
  end

  def is_city?(text)
    return unless is_command?(text)

    response = states.keep_if do |state|
      !state.cities.find{ |city| text == "/#{ city.permalink }" }.nil?
    end.compact.empty?

    !response
  end

  def message_for_command(command)
    command.gsub('/', '')
  end
end