require 'exec'
require 'find'

class Overviewer
  def self.render(world_dir, tile_dir)
    config_py = File.expand_path("#{world_dir}/config.py")

    level_dir = level_paths(world_dir).first

    File.write config_py, <<-EOS
northdirection = "upper-right"
rendermode = "smooth_lighting"

worlds['world'] = "#{level_dir}"
outputdir = '#{tile_dir}'

def signFilter(poi):
  "All signs"
  return poi['id'] == 'Sign'

renders["smooth_lighting"] = {
  'world': 'world',
  'title' : 'honey badger',
  'markers': [dict(name="All signs", filterFunction=signFilter)]
}

EOS
    Exec.run ["overviewer.py", "--check-tiles", "--config=#{config_py}"]
    Exec.run ["overviewer.py", "--genpoi", "--config=#{world_dir}/config.py"]
  end

  def self.map_data(tile_dir)
    begin
     markers_db = File.read("#{tile_dir}/markersDB.js")
     markers = JSON.parse(markers_db.match(/\[(.*)\]/m)[0])
     markers = markers.map do |marker|
       # transform {'id' => 'Sign'} to {'type' => 'sign'}
       marker.each_with_object({}){|(k,v),h| h[(k == 'id' ? 'type' : k)] = (k == 'id' ? v.downcase : v) }
     end

     settings_js = File.read "#{tile_dir}/overviewerConfig.js"
     tileSize = settings_js.match(/"tileSize":\s+?(\d+)/m)[1].to_i
     zoomLevels = settings_js.match(/"zoomLevels":\s+?(\d+)/)[1].to_i

     matches = settings_js.match(/"spawn":\s*\[([^\]]+)\]/)
     if matches and (spawn = matches[1])
       x, y, z = spawn.split(',').map{|i| i.strip.to_i }
       markers << {
         type: 'spawn',
         x: x, y: y, z: z
       }
     end

     {
            markers: markers,
           tileSize: tileSize,
         zoomLevels: zoomLevels
     }
   rescue
   end
  end

  def self.level_paths(root)
    level_dats(root).map{|file| File.dirname(file).gsub(/^\.\//, '') }
  end

  def self.level_dats(root)
    paths = []
    Find.find(root) do |path|
      if path =~ /\/(level|uid)\.dat$/
        paths << path
      end
    end
    paths
  end
end