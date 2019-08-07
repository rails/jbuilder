require 'test_helper'

class TurboStreamer::OptionsTest < ActiveSupport::TestCase

  setup do
    @default_encoder = TurboStreamer.class_variable_get('@@default_encoders')[:json]
    @default_options = TurboStreamer.class_variable_get('@@encoder_options').dup
  end
  
  teardown do
    TurboStreamer.set_default_encoder(:json, @default_encoder, @default_options)
  end
  
  test 'setting default options' do
    TurboStreamer.set_default_encoder(:json, :oj)
    TurboStreamer.set_default_encoder_options(:oj, {buffer_size: 2_048})
    ::Oj::StreamWriter.expects(:new).with {|a, b| b == {mode: :json, buffer_size: 2_048} }
    TurboStreamer.new
  end
  
  
  test 'setting default encoder and options' do
    TurboStreamer.set_default_encoder(:json, :oj, {buffer_size: 1_024})
    ::Oj::StreamWriter.expects(:new).with {|a, b| b == {mode: :json, buffer_size: 1_024} }
    TurboStreamer.new
  end

end

    