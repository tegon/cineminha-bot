require 'test_helper'

class SessionsSerializerTest < Minitest::Test
  def setup
    cine = Cine.new('Cine Araújo', 'Nova York')
    @sessions = [
      Session.new(cine, 'LEG3D', '22:00', 'Sala 3'),
      Session.new(cine, 'DUB3D', '14:00', 'Sala 1'),
      Session.new(cine, 'DUBLADO3DDUBLADO', '16:00', 'Sala 2'),
      Session.new(cine, 'DUBLADODUBLADO3D', '18:00', 'Sala 3')
    ]
    @serializer = SessionsSerializer.new(@sessions)
  end

  def test_that_sessions_is_set
    assert_equal @sessions, @serializer.sessions
  end

  def test_to_message_output
    output = [
      "Horário: 22:00\nSala 3\nCine Araújo - Nova York\nLEG3D",
      "Horário: 14:00\nSala 1\nCine Araújo - Nova York\nDUB3D",
      "Horário: 16:00\nSala 2\nCine Araújo - Nova York\nDUBLADO3D",
      "Horário: 18:00\nSala 3\nCine Araújo - Nova York\nDUBLADO3D"
    ]
    assert_equal output.join("\n \n"), @serializer.to_message
  end
end
