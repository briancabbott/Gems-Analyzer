
require 'nokogiri'
require 'open-uri'

# Represents a Scan 
class GemScanEvent
  
end

class GemDirectoryEntry 

  def initialize(directory_name = nil, directory_uri = nil, 
    expected_entries_count = nil, directory_sub_pages = []) 
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
  def initialize(gem_page_uri = nil, gem_name = nil, gem_description = nil, 
    current_version = nil,
    current_version_download_link = nil, 
    total_downloads = nil, 
    total_downloads_on_current_version = nil) 
    @gem_page_uri = gem_page_uri
    @gem_name = gem_name 
    @gem_description = gem_description 
    @current_version = current_version
    @current_version_download_link = current_version_download_link 
    @total_downloads = total_downloads
    @total_downloads_on_current_version = total_downloads_on_current_version 
  end

  def gem_page_uri()
    @gem_page_uri
  end
  def gem_page_uri=(gem_page_uri)
    @gem_page_uri = gem_page_uri
  end

  def gem_name() 
    @gem_name
  end
  def gem_name=(gem_name) 
    @gem_name = gem_name
  end
  
  def gem_description()
    @gem_description    
  end
  def gem_description=(gem_description)
    @gem_description = gem_description   
  end
  
  def current_version() 
    @current_version
  end 
  def current_version=(current_version) 
    @current_version = current_version
  end 
  
  def current_version_download_link()
    @current_version_download_link
  end
  def current_version_download_link=(current_version_download_link)
    @current_version_download_link = current_version_download_link
  end
  
  def total_downloads()
    @total_downloads
  end
  def total_downloads=(total_downloads)
    @total_downloads = total_downloads
  end
  
  def total_downloads_on_current_version()
    @total_downloads_on_current_version
  end
  def total_downloads_on_current_version=(total_downloads_on_current_version)
    @total_downloads_on_current_version = total_downloads_on_current_version
  end
end

# Represents an individual Ruby Gem instance. 
# class GemInstance 
  # gem_title
  # gem_uri
# end


class GemScanner
  @@root_gems_uri = 'http://rubygems.org'
  
  @scanned_gems = []
  
  # 
  def capture_directory_list(html_doc) 
    puts "entering capture_directory_list"    
    gem_directory_map = Hash.new
    html_doc.search('div[@class="directory border"]/ol/li/a').each { |node| 
      gemDirectory = GemDirectoryEntry.new(nil, nil, nil, nil)
      gemDirectory.directory_name = node.text
      gemDirectory.directory_uri = @@root_gems_uri + node['href']
      
      gem_directory_map[node.text] = gemDirectory
    }
    
    # 
    # Grab the GemDirectoryEntry.expected_entries_count() value.
    #
    gem_directory_map.each { | k, v | 
      directory_page = Nokogiri::HTML(open(v.directory_uri()))
      directory_page.search('p[@class="entries"]').each { |node| 
        display_string = node.text
        display_string = display_string.scan(/of \d+/)[0]
        display_string = display_string.sub("of ", "")
        v.expected_entries_count = display_string.to_i()
      }
      
      
      directory_page.search('div[@class="pagination"]').each { |node|
        # find the last page index.
        last_page_index = 0
        node.children().each { | child_node | 
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
        
        (1..last_page_index).each { | page_idx |
          v.directory_sub_pages() << @@root_gems_uri + '/gems?letter=' + v.directory_name() + '&page=' + page_idx.to_s
        }
        
        v.directory_sub_pages().each { |sub_page| 
          puts sub_page 
          gems_subdir_page = Nokogiri::HTML(open(sub_page))
          gems_subdir_page.search('div[@class="gems border"]/ol/li').each { |gem_entity|
            gem_entity.search('a').each { | href_elem | 
              gem_uri = @@root_gems_uri + href_elem['href']
              title = href_elem.children()[1].text
              
              gemPage = GemPage.new
              gemPage.gem_page_uri = gem_uri
              gemPage.gem_name = title
  
              if (@scanned_gems == nil)
                @scanned_gems = []
              end
              @scanned_gems << gemPage
            }
          }
        } 
      }
    }

    # TODO: move to print method
    gem_directory_map.each { | k, v | 
      directory_name = v.directory_name
      directory_uri = v.directory_uri
      expected_entries_count = v.expected_entries_count
      # directory_sub_pages = @directory_sub_pages

      puts "#{directory_name}, #{directory_uri}, #{expected_entries_count}"
    }
    
    @scanned_gems.each { |gem_page|
      puts "opening: " + gem_page.gem_page_uri
      gem_page = Nokogiri::HTML(open(gem_page.gem_page_uri))
      page_description = gem_page.search('div[@id="markup"]').first.text
      puts page_description
    }
  end
  
  def scan_gems()
    doc = Nokogiri::HTML(open(@@root_gems_uri + "/gems"))
    capture_directory_list(doc)
    # puts doc
  end
end

GemScanner.new.scan_gems()
