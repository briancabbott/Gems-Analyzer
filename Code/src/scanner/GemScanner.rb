
require 'nokogiri'
require 'open-uri'

class GemDirectoryEntry 

  def initialize() 
    @directory_name = nil
    @directory_uri = nil
    @expected_entries_count = nil
    @directory_sub_pages = []
  end
  
  def initialize(directory_name, directory_uri, expected_entries_count, directory_sub_pages) 
    @directory_name = directory_name
    @directory_uri = directory_uri
    @expected_entries_count = expected_entries_count
    @directory_sub_pages = directory_sub_pages
  end

  def directory_name() 
    @directory_name
  end 
  def directory_name=(directory_name) 
    @directory_name = directory_name
  end 
    
  def directory_uri() 
    @directory_uri
  end
  def directory_uri=(directory_uri) 
    @directory_uri = directory_uri
  end
    
  def expected_entries_count() 
    @expected_entries_count
  end
  def expected_entries_count=(expected_entries_count) 
    @expected_entries_count = expected_entries_count
  end
    
  def directory_sub_pages() 
    @directory_sub_pages
  end
  def directory_sub_pages=(directory_sub_pages) 
    @directory_sub_pages = directory_sub_pages
  end
end

class GemPage
  # gem_name, 
  # gem_description, 
  # current_version, 
  # current_version_download_link, 
  # total_downloads, 
  # total_downloads_on_current_version
end

# Represents an individual Ruby Gem instance. 
# class GemInstance 
  # gem_title
  # gem_uri
# end


class GemScanner
  @@root_gems_uri = 'http://rubygems.org'
  
  # 
  def capture_directory_list(html_doc) 
    puts "entering capture_directory_list"    
    gem_directory_map = Hash.new
    html_doc.search('div[@class="directory border"]/ol/li/a').each { |node| 
      gemDirectory = GemDirectoryEntry.new(nil, nil, nil, nil)
      
      gemDirectory.directory_name = node.text
      gemDirectory.directory_uri = @@root_gems_uri + node['href']
      
      gem_directory_map[node.text] = gemDirectory
      
      puts 'added ' + node.text
    }
    
    #
    # Grab the GemDirectoryEntry.expected_entries_count() value.
    #
    gem_directory_map.each {|k,v| 
      directory_page = Nokogiri::HTML(open(v.directory_uri()))
      directory_page.search('p[@class="entries"]').each { |node| 
        display_string = node.text
        display_string = display_string.scan(/of \d+/)[0]
        display_string = display_string.sub("of ", "")
        v.expected_entries_count = display_string.to_i()
      }
      
      directory_page.search('div[@class="pagination"]').each { |node|
        last_page_index = 0
        node.children().each { |child_node| 
          page_index = /\d+/.match(child_node.text)
          if (page_index != nil) 
            if (page_index.to_s.to_i > last_page_index)
              last_page_index = page_index.to_s.to_i
            end
          end
        }
        
        # /gems?letter=A&page=4
        # /gems?letter=A&page=4
        if (v.directory_sub_pages() == nil) 
          v.directory_sub_pages = []
        end
        
        (1..last_page_index).each { |page_idx|
          v.directory_sub_pages() << '/gems?letter=' + v.directory_name() + '&page=' + page_idx.to_s
        }
        
        v.directory_sub_pages().each { |sub_page| puts sub_page } 
      }
    }

    gem_directory_map.each {|k,v| 
      directory_name = v.directory_name
      directory_uri= v.directory_uri
      expected_entries_count = v.expected_entries_count
      # directory_sub_pages = @directory_sub_pages

      puts "#{directory_name}, #{directory_uri}, #{expected_entries_count}"
    }
  end
  
  def scan_gems()
    doc = Nokogiri::HTML(open(@@root_gems_uri + "/gems"))
    capture_directory_list(doc)
    # puts doc
  end
end

GemScanner.new.scan_gems()
