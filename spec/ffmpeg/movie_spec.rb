RSpec.describe FFMPEG::Movie do
  describe "initializing" do
    context "given a non existing file" do
      it "should throw ArgumentError" do
        expect { FFMPEG::Movie.new("i_dont_exist") }.to raise_error(Errno::ENOENT, /does not exist/)
      end
    end

    context "given a file containing a single quotation mark in the filename" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/awesome'movie.mov") }

      it "should run ffmpeg successfully" do
        expect(movie.duration).to eq(7.56)
        expect(movie.frame_rate).to eq(16.75)
      end
    end

    context "given a non movie file" do
      subject(:movie) { FFMPEG::Movie.new(__FILE__) }

      it "should not be valid" do
        expect(movie).to_not be_valid
      end

      it "should have a duration of 0" do
        expect(movie.duration).to eq(0)
      end

      it "should have nil height" do
        expect(movie.height).to be_nil
      end

      it "should have nil width" do
        expect(movie.width).to be_nil
      end

      it "should have nil frame_rate" do
        expect(movie.frame_rate).to be_nil
      end
    end

    context "given an empty flv file (could not find codec parameters)" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/empty.flv") }

      it "should not be valid" do
        expect(movie).to_not be_valid
      end
    end

    context "given a broken mp4 file" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/broken.mp4") }

      it "should not be valid" do
        expect(movie).to_not be_valid
      end

      it "should have nil calculated_aspect_ratio" do
        expect(movie.calculated_aspect_ratio).to be_nil
      end
    end

    context "given a weird aspect ratio file" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

      it "should parse the DAR" do
        expect(movie.dar).to eq("704:405")
      end

      it "should have correct calculated_aspect_ratio" do
        # substringed to be 1.9 compatible
        expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.7382716049382")
      end
    end

    context "given an impossible DAR" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_weird_dar.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should parse the DAR" do
        expect(movie.dar).to eq('0:1')
      end

      it "should calulate using width and height instead" do
        # substringed to be 1.9 compatible
        expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.7777777777777")
      end
    end

    context "given a weird storage/pixel aspect ratio file" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

      it "should parse the SAR" do
        expect(movie.sar).to eq("64:45")
      end

      it "should have correct calculated_pixel_aspect_ratio" do
        # substringed to be 1.9 compatible
        expect(movie.calculated_pixel_aspect_ratio.to_s[0..14]).to eq("1.4222222222222")
      end
    end

    context "given a colorspace with parenthesis but no commas such as yuv420p(tv)" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_colorspace_with_parenthesis_but_no_comma.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should have correct video stream" do
        expect(movie.colorspace).to eq("yuv420p(tv)")
      end
    end

    context "given an impossible SAR" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_weird_sar.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should parse the SAR" do
        expect(movie.sar).to eq("0:1")
      end

      it "should using square SAR, 1.0 instead" do
        # substringed to be 1.9 compatible
        expect(movie.calculated_pixel_aspect_ratio.to_s[0..14]).to eq("1")
      end
    end

    context "given a file with ISO-8859-1 characters in output" do
      it "should not crash" do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_iso-8859-1.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        expect { FFMPEG::Movie.new(__FILE__) }.to_not raise_error
      end
    end

    context "given a file with 5.1 audio" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_surround_sound.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should have 6 audio channels" do
        expect(movie.audio_channels).to eq(6)
      end
    end

    context "given a file with no audio" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_no_audio.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should have nil audio channels" do
        expect(movie.audio_channels).to be_nil
      end
    end

    context "given a file with non supported audio" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should not be valid" do
        expect(movie).not_to be_valid
      end
    end

    context "given a file with complex colorspace and decimal fps" do
      subject(:movie) do
        fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_complex_colorspace_and_decimal_fps.txt"))
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        FFMPEG::Movie.new(__FILE__)
      end

      it "should know the framerate" do
        expect(movie.frame_rate).to eq(23.98)
      end

      it "should know the colorspace" do
        expect(movie.colorspace).to eq("yuv420p(tv, bt709)")
      end

      it "should know the width and height" do
        expect(movie.width).to eq(960)
        expect(movie.height).to eq(540)
      end
    end

    context "given an awesome movie file" do
      subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/awesome movie.mov") }

      it "should remember the movie path" do
        expect(movie.path).to eq("#{fixture_path}/movies/awesome movie.mov")
      end

      it "should parse duration to number of seconds" do
        expect(movie.duration).to eq(7.56)
      end

      it "should parse the bitrate" do
        expect(movie.bitrate).to eq(481)
      end

      it "should return nil rotation when no rotation exists" do
        expect(movie.rotation).to be_nil
      end

      it "should parse the creation_time" do
        expect(movie.creation_time).to eq(Time.parse("2010-02-05 16:05:04"))
      end

      it "should parse video stream information" do
        expect(movie.video_stream).to eq("h264 (Main) (avc1 / 0x31637661), yuv420p(tv, bt709), 640x480 [SAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 600 tbr, 600 tbn, 1200 tbc (default)")
      end

      it "should know the video codec" do
        expect(movie.video_codec).to =~ /h264/
      end

      it "should know the colorspace" do
        expect(movie.colorspace).to eq("yuv420p(tv, bt709)")
      end

      it "should know the resolution" do
        expect(movie.resolution).to eq("640x480")
      end

      it "should know the video bitrate" do
        expect(movie.video_bitrate).to eq(371)
      end

      it "should know the width and height" do
        expect(movie.width).to eq(640)
        expect(movie.height).to eq(480)
      end

      it "should know the framerate" do
        expect(movie.frame_rate).to eq(16.75)
      end

      it "should parse audio stream information" do
        expect(movie.audio_stream).to eq("aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 75 kb/s (default)")
      end

      it "should know the audio codec" do
        expect(movie.audio_codec).to =~ /aac/
      end

      it "should know the sample rate" do
        expect(movie.audio_sample_rate).to eq(44100)
      end

      it "should know the number of audio channels" do
        expect(movie.audio_channels).to eq(2)
      end

      it "should know the audio bitrate" do
        expect(movie.audio_bitrate).to eq(75)
      end

      it "should should be valid" do
        expect(movie).to be_valid
      end

      it "should calculate the aspect ratio" do
        expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.3333333333333") # substringed to be 1.9 compatible
      end

      it "should know the file size" do
        expect(movie.size).to eq(455546)
      end

      it "should know the container" do
        expect(movie.container).to eq("mov,mp4,m4a,3gp,3g2,mj2")
      end
    end
  end

  context "given a rotated movie file" do
    subject(:movie) { FFMPEG::Movie.new("#{fixture_path}/movies/sideways movie.mov") }

    it "should parse the rotation" do
      expect(movie.rotation).to eq(90)
    end
  end

  describe "transcode" do
    it "should run the transcoder" do
      movie = FFMPEG::Movie.new("#{fixture_path}/movies/awesome movie.mov")

      transcoder_double = double(FFMPEG::Transcoder)
      FFMPEG::Transcoder.should_receive(:new).
        with(movie, "#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width).
        and_return(transcoder_double)
      transcoder_double.should_receive(:run)

      movie.transcode("#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width)
    end
  end

  describe "screenshot" do
    it "should run the transcoder with screenshot option" do
      movie = FFMPEG::Movie.new("#{fixture_path}/movies/awesome movie.mov")

      transcoder_double = double(FFMPEG::Transcoder)
      FFMPEG::Transcoder.should_receive(:new).
        with(movie, "#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480", screenshot: true}, preserve_aspect_ratio: :width).
        and_return(transcoder_double)
      transcoder_double.should_receive(:run)

      movie.screenshot("#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480"}, preserve_aspect_ratio: :width)
    end
  end
end
