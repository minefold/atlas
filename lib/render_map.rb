require 'sidekiq'
require 'tmpdir'
require 'tempfile'

$:.unshift(File.expand_path('..', __FILE__))

require 'exec'
require 'overviewer'

class RenderMapWorker
  include Sidekiq::Worker

  def perform(id, snapshot_url)
    # boto library uses different ENV vars from PC tools
    ENV['AWS_ACCESS_KEY_ID'] = ENV['AWS_ACCESS_KEY']
    ENV['AWS_SECRET_ACCESS_KEY'] = ENV['AWS_SECRET_KEY']

    chtmpdir do |dir|
      puts "#{`pwd`.strip}"
      chmkdir('snapshot') do
        restore_snapshot(snapshot_url)
      end
      chmkdir('tiles/smooth_lighting') do
        restore_tile_cache(id)
      end
      Overviewer.render('snapshot', 'tiles')
      chmkdir('tiles/smooth_lighting') do
        upload_tiles(id)
      end

      notify_map_rendered(id, snapshot_url, 'tiles')

      chmkdir('tiles/smooth_lighting') do
        archive_tile_cache(id)
      end
    end
  end

  def chmkdir(dir, &blk)
    FileUtils.mkdir_p(dir)
    Dir.chdir(dir, &blk)
  end

  def chtmpdir(&blk)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &blk)
    end
  end

  def restore_snapshot(url)
    Exec.run(["restore-dir", url])
  end

  def restore_tile_cache(id)
    Exec.run(["restore-dir", "http://mutli-atlas.s3.amazonaws.com/cache/#{id}.tar.lzo"])
  rescue
    # don't worry if cache doesn't exist
  end

  def archive_tile_cache(id)
    Tempfile.open(id.to_s) do |archive|
      Exec.run(["tar",
        "--use-compress-program", "lzop",
        "-cf", archive.path] +  Dir.glob('*'))
      Exec.run(["s3cmd", "put", "--multipart-chunk-size-mb=512", archive.path, "s3://mutli-atlas/cache/#{id}.tar.lzo"])
    end
  end

  def upload_tiles(id)
    # parallel upload tiles
    Exec.run(["s3-parallel-put",
      "--bucket=minefold-production-maps",
      "--prefix=#{id}",
      "."])

    # clean up deleted tiles
    Exec.run(["s3cmd",
      "sync",
      "--delete-removed",
      ".",
      "s3://minefold-production-maps/#{id}/"])
  end

  def notify_map_rendered(id, snapshot_url, tile_dir)
    payload = {
      event: 'map_rendered',
      id: id,
      snapshot_url: snapshot_url,
      created: Time.now.to_i,
      map_data: Overviewer.map_data(tile_dir) || {}
    }
    RestClient.post(
      'https://minefold.com/webhooks/atlas',
      payload.to_json,
      :content_type => :json,
      :accept => :json
    )
  end
end