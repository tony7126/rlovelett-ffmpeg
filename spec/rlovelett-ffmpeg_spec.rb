RSpec.describe FFMPEG do
  describe "logger" do
    it "should be a Logger" do
      expect(FFMPEG.logger).to be_instance_of(Logger)
    end

    it "should be at info level" do
      FFMPEG.logger = nil # Reset the logger so that we get the default
      expect(FFMPEG.logger.level).to eq(Logger::INFO)
    end

    it "should be assignable" do
      new_logger = Logger.new(STDOUT)
      FFMPEG.logger = new_logger
      expect(FFMPEG.logger).to eq(new_logger)
    end
  end

  describe "ffmpeg_binary" do
    after(:each) do
      FFMPEG.ffmpeg_binary = nil
    end

    it "should default to 'ffmpeg'" do
      expect(FFMPEG.ffmpeg_binary).to eq('ffmpeg')
    end

    it "should be assignable" do
      new_binary = '/usr/local/bin/ffmpeg'
      FFMPEG.ffmpeg_binary = new_binary
      expect(FFMPEG.ffmpeg_binary).to eq(new_binary)
    end
  end
end
