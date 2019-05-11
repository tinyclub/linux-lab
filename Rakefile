#!/usr/bin/env ruby
#encoding: utf-8

require "rubygems"
require 'rake'
require 'yaml'
require 'time'

SOURCE = "."
CONFIG = {
  'version' => "0.3.0",
  'themes' => File.join(SOURCE, "_includes", "themes"),
  'layouts' => File.join(SOURCE, "_layouts"),
  'posts' => File.join(SOURCE, "_posts"),
  'pages' => File.join(SOURCE, "pages"),
  'post_ext' => "md",
  'theme_package_version' => "0.1.0",
  'site' => "TinyLab.org",
  'author' => "YOUR NAME",
  'nick' => "YOUR NICK NAME",
}

# Path configuration helper
module JB
  class Path
    SOURCE = "."
    Paths = {
      :layouts => "_layouts",
      :themes => "_includes/themes",
      :theme_assets => "assets/themes",
      :theme_packages => "_theme_packages",
      :posts => "_posts"
    }
    
    def self.base
      SOURCE
    end

    # build a path relative to configured path settings.
    def self.build(path, opts = {})
      opts[:root] ||= SOURCE
      path = "#{opts[:root]}/#{Paths[path.to_sym]}/#{opts[:node]}".split("/")
      path.compact!
      File.__send__ :join, path
    end
  
  end #Path
end #JB

# Usage: rake post author='Author' nick="Nick Name" title="A Title" [date="2012-02-09"] [tags=[tag1,tag2]] [categories="[category1,category2]"] \
#                  group='Article Group' album='Article Series' tagline='subtitle' description="summary"  \
#                  slug='URL with English characeters'
#

desc "Begin a new post in #{CONFIG['posts']}"
task :post do
  abort("rake aborted: '#{CONFIG['posts']}' directory not found.") unless FileTest.directory?(CONFIG['posts'])
  title = ENV["title"] || "new-post"
  if ENV["slug"]
    slug = ENV["slug"].downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  else
    slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end
  begin
    date = (ENV['date'] ? Time.parse(ENV['date']) : Time.now).strftime('%Y-%m-%d-%H-%M-%S')
    post_date = (ENV['date'] ? Time.parse(ENV['date']) : Time.now).strftime('%b %d, %Y')
  rescue => e
    puts "Error - date format must be YYYY-MM-DD, please check you typed it correctly!"
    exit -1
  end
  filename = File.join(CONFIG['posts'], "#{date}-#{slug}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  # Build Categories
  if ENV["categories"]
    categories_in = ENV["categories"][1..-2]
    categories = categories_in.gsub(/-/,' ').split(",")
  else
    category_list = "\n  - category1\n  - category2"
    categories = []
  end
  categories.each do |i|
    category_list = "#{category_list}\n  - #{i}"
  end

  # Build tags
  if ENV["tags"]
    tags_in = ENV["tags"][1..-2]
    tags = tags_in.gsub(/-/,' ').split(",")
  else
    tag_list = "\n  - tag1\n  - tag2"
    tags = []
  end
  tags.each do |i|
    tag_list = "#{tag_list}\n  - #{i}"
  end

  # Build tagline (subtitle)
  if ENV["tagline"]
    tagline = ENV["tagline"]
    tagline = "tagline: '#{tagline}'"
  else
    tagline = '# tagline: " 子标题，如果存在的话 "'
  end
  
  # Build draft (publish or hide, true for hidden, false for publish)
  if ENV["draft"]
    draft = ENV["draft"]
    draft = "draft: #{draft}"
  else
    draft = 'draft: false'
  end

  # Build album (series)
  if ENV["album"]
    album = ENV["album"]
    album = "album: '#{album}'"
  else
    album = '# album: " 所属文章系列/专辑，如果有的话"'
  end

  # Build group (topic type)
  if ENV["group"]
    group = ENV["group"]
    group = "group: '#{group}'"
  else
    group = '# group: " 默认为 original，也可选 translation, news, resume or jobs, 详见 _data/groups.yml"'
  end

  # Build the author
  if ENV["author"]
    author = ENV["author"]
    author = "author: '#{author}'"
  else
    author = "author: #{CONFIG['author']}"
  end

  # Build the nick
  if ENV["nick"]
    nick = ENV["nick"]
    nick = "#{nick}"
  else
    nick = "#{CONFIG['nick']}"
  end

  # Build the permalink
  if ENV["slug"]
    permalink = ENV["slug"]
    permalink = "permalink: /#{permalink}/"
  else
    permalink = "permalink: /#{slug}/"
  end

  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "#{author}"
    post.puts "title: \"#{title.gsub(/-/,' ')}\""
    post.puts "#{draft}"
    post.puts "#{tagline}"
    post.puts "#{album}"
    post.puts "#{group}"
    post.puts 'license: "cc-by-sa-4.0"'
    post.puts "#{permalink}"
    post.puts 'description: " 文章摘要 "'
    post.puts "category:#{category_list}"
    post.puts "tags:#{tag_list}"
    post.puts "---"
    post.puts ""
    post.puts "> By #{nick} of [#{CONFIG['site']}][1]"
    post.puts "> #{post_date}"
    post.puts ""
    post.puts "本模板为 泰晓科技 采用的文档模板与约定，为规范文章风格与质量，请在撰稿前务必仔细阅读！"
    post.puts ""
    post.puts "这里分别就几个方面展开介绍："
    post.puts ""
    post.puts "## 文章分类"
    post.puts ""
    post.puts "为了更好地展示和组织文章，请尽量采用 `_data/categories.yml` 中的分类，如果确实有新增，请在发文前单独提交 PR 更新该文件。"
    post.puts ""
    post.puts "## 内容列表"
    post.puts ""
    post.puts "1. 数字列表，条目 1"
    post.puts "  * 普通列表，条目 1"
    post.puts "  * 普通列表，条目 2"
    post.puts ""
    post.puts "2. 数字列表，条目 2"
    post.puts ""
    post.puts "## 代码缩进"
    post.puts ""
    post.puts "代码在正文下，用 4 个空格缩进："
    post.puts ""
    post.puts "    #include <stdio.h>"
    post.puts ""
    post.puts "    int main(void)"
    post.puts "    {"
    post.puts "       printf('Hello, World!');"
    post.puts "    }"
    post.puts ""
    post.puts "*注*: 如果要跟列表一起缩进显示，得添加相应空格。"
    post.puts ""
    post.puts "## 正文内内嵌代码"
    post.puts ""
    post.puts "如果正文中包含了命令、接口、代码片段、变量等属于代码的部分时，请用 \` 括起来，例如：`grep Free /proc/meminfo`，用法为："
    post.puts ""
    post.puts "    `grep Free /proc/meminfo`"
    post.puts ""
    post.puts "## 中英文以及数字混排"
    post.puts ""
    post.puts "当中 English 文以及中文、数字混排时，记得在 English 和数字，例如 1 2 3 4 周边添加空格，进而确保可阅读性，即 Readability。"
    post.puts ""
    post.puts "## 表格用法"
    post.puts ""
    post.puts "| 标题 1      | 标题 2     | 标题 3          |"
    post.puts "|-------------|-----------:|:---------------:|"
    post.puts "| 左对齐      |右对齐      | 居中对齐        |"
    post.puts ""
    post.puts "## 在正文中嵌入图片"
    post.puts ""
    post.puts "Markdown 基本语法如下："
    post.puts ""
    post.puts "![图片名](/images/weibo/tinylaborg.jpg '图片内容提示，可选')"
    post.puts ""
    post.puts "*注*：如果想规范图片大小，想增加额外的特性，可以用 html 的 `<img>` 标记。"
    post.puts ""
    post.puts "## 链接以及各类内容混排"
    post.puts ""
    post.puts "### 链接"
    post.puts ""
    post.puts "* [链接用法一][1]"
    post.puts ""
    post.puts "  在列表后面放入脚本，为了确保跟列表一起缩进，需要额外增加两个空格："
    post.puts ""
    post.puts "      #!/bin/bash"
    post.puts "      echo 'Hello, World.'"
    post.puts ""
    post.puts ""
    post.puts "* [另外一种链接用法](http://tinylab.org)"
    post.puts ""
    post.puts "  在列表后面再嵌入子列表，包括数字列表和非数字列表："
    post.puts ""
    post.puts "  * Another list"
    post.puts "    * Another list"
    post.puts "      1. Third list"
    post.puts "      2. Third list"
    post.puts ""
    post.puts ""
    post.puts "* 第三种链接用法：<http://tinylab.org>"
    post.puts ""
    post.puts "### 更复杂的列表用法"
    post.puts ""
    post.puts "1. 表项 1"
    post.puts ""
    post.puts "    这里再嵌入代码："
    post.puts ""
    post.puts "        #include <stdio.h>"
    post.puts ""
    post.puts "        int main() { return 0; }"
    post.puts ""
    post.puts "2. 表项 2"
    post.puts ""
    post.puts "    这里嵌入图片："
    post.puts ""
    post.puts "    ![图片名](/images/weibo/tinylaborg.jpg '图片内容描述信息')"
    post.puts ""
    post.puts "3. 表项 3"
    post.puts ""
    post.puts "    普通正文"
    post.puts ""
    post.puts "4. 表项 4"
    post.puts "  * 数字表项嵌入非数字表项，表项 1"
    post.puts "  * 表项 2"
    post.puts ""
    post.puts "        | 标题 1      | 标题 2     | 标题 3          |"
    post.puts "        |-------------|-----------:|:---------------:|"
    post.puts "        | 左对齐      |右对齐      | 居中对齐        |"
    post.puts ""
    post.puts "*注*：数字列表跟普通列表有一个差别是，数字列表后面如果要加正文自动缩进，得增加 4 个空格，而普通列表只需要两个。估计是 Markdown 解释器的问题，请尽量遵循这个约定吧。"
    post.puts ""
    post.puts "## 正文引用"
    post.puts ""
    post.puts "如果要引用第三方的信息，可以这么做："
    post.puts ""
    post.puts "> 这里是来自第三方的信息，信息内容可以用普通的 Markdown 语法来标记[链接][1]、**加粗**、`命令`等等，很灵活。。。"
    post.puts ""
    post.puts "[1]: http://tinylab.org"

  end
end # task :post

# Usage: rake page name="about.html"
# You can also specify a sub-directory path.
# If you don't specify a file extention we create an index.html at the path specified
desc "Create a new page."
task :page do
  name = ENV["name"] || "new-page.md"
  filename = File.join(SOURCE, "#{name}")
  filename = File.join(filename, "index.html") if File.extname(filename) == ""
  title = File.basename(filename, File.extname(filename)).gsub(/[\W\_]/, " ").gsub(/\b\w/){$&.upcase}
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  filename = File.join(CONFIG['pages'], filename)

  mkdir_p File.dirname(filename)
  puts "Creating new page: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: page"
    post.puts "author: #{CONFIG['author']}"
    post.puts "title: \"#{title}\""
    post.puts 'draft: false'
    post.puts '# tagline: " subtitle "'
    post.puts '# album: " belongs to an page series"'
    post.puts '# group: " belongs to navigation or the others"'
    post.puts '# comments: false'
    post.puts '# plugin: tab'
    post.puts '# toc: false'
    post.puts '# qrcode: false'
    post.puts "permalink: /#{title}/"
    post.puts 'description: ""'
    post.puts "category: #{category}"
    post.puts "tags: #{tags}"
    post.puts "---"
  end
end # task :page

desc "Launch preview environment"
task :preview do
  system "jekyll serve -w"
end # task :preview

# Public: Alias - Maintains backwards compatability for theme switching.
task :switch_theme => "theme:switch"

namespace :theme do
  
  # Public: Switch from one theme to another for your blog.
  #
  # name - String, Required. name of the theme you want to switch to.
  #        The theme must be installed into your JB framework.
  #
  # Examples
  #
  #   rake theme:switch name="the-program"
  #
  # Returns Success/failure messages.
  desc "Switch between Jekyll-bootstrap themes."
  task :switch do
    theme_name = ENV["name"].to_s
    theme_path = File.join(CONFIG['themes'], theme_name)
    settings_file = File.join(theme_path, "settings.yml")
    non_layout_files = ["settings.yml"]

    abort("rake aborted: name cannot be blank") if theme_name.empty?
    abort("rake aborted: '#{theme_path}' directory not found.") unless FileTest.directory?(theme_path)
    abort("rake aborted: '#{CONFIG['layouts']}' directory not found.") unless FileTest.directory?(CONFIG['layouts'])

    Dir.glob("#{theme_path}/*") do |filename|
      next if non_layout_files.include?(File.basename(filename).downcase)
      puts "Generating '#{theme_name}' layout: #{File.basename(filename)}"

      open(File.join(CONFIG['layouts'], File.basename(filename)), 'w') do |page|
        page.puts "---"
        page.puts File.read(settings_file) if File.exist?(settings_file)
        page.puts "layout: default" unless File.basename(filename, ".html").downcase == "default"
        page.puts "---"
        page.puts "{% include JB/setup %}"
        page.puts "{% include themes/#{theme_name}/#{File.basename(filename)} %}" 
      end
    end
    
    puts "=> Theme successfully switched!"
    puts "=> Reload your web-page to check it out =)"
  end # task :switch
  
  # Public: Install a theme using the theme packager.
  # Version 0.1.0 simple 1:1 file matching.
  #
  # git  - String, Optional path to the git repository of the theme to be installed.
  # name - String, Optional name of the theme you want to install.
  #        Passing name requires that the theme package already exist.
  #
  # Examples
  #
  #   rake theme:install git="https://github.com/jekyllbootstrap/theme-twitter.git"
  #   rake theme:install name="cool-theme"
  #
  # Returns Success/failure messages.
  desc "Install theme"
  task :install do
    if ENV["git"]
      manifest = theme_from_git_url(ENV["git"])
      name = manifest["name"]
    else
      name = ENV["name"].to_s.downcase
    end

    packaged_theme_path = JB::Path.build(:theme_packages, :node => name)
    
    abort("rake aborted!
      => ERROR: 'name' cannot be blank") if name.empty?
    abort("rake aborted! 
      => ERROR: '#{packaged_theme_path}' directory not found.
      => Installable themes can be added via git. You can find some here: http://github.com/jekyllbootstrap
      => To download+install run: `rake theme:install git='[PUBLIC-CLONE-URL]'`
      => example : rake theme:install git='git@github.com:jekyllbootstrap/theme-the-program.git'
    ") unless FileTest.directory?(packaged_theme_path)
    
    manifest = verify_manifest(packaged_theme_path)
    
    # Get relative paths to packaged theme files
    # Exclude directories as they'll be recursively created. Exclude meta-data files.
    packaged_theme_files = []
    FileUtils.cd(packaged_theme_path) {
      Dir.glob("**/*.*") { |f| 
        next if ( FileTest.directory?(f) || f =~ /^(manifest|readme|packager)/i )
        packaged_theme_files << f 
      }
    }
    
    # Mirror each file into the framework making sure to prompt if already exists.
    packaged_theme_files.each do |filename|
      file_install_path = File.join(JB::Path.base, filename)
      if File.exist? file_install_path and ask("#{file_install_path} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
        next
      else
        mkdir_p File.dirname(file_install_path)
        cp_r File.join(packaged_theme_path, filename), file_install_path
      end
    end
    
    puts "=> #{name} theme has been installed!"
    puts "=> ---"
    if ask("=> Want to switch themes now?", ['y', 'n']) == 'y'
      system("rake switch_theme name='#{name}'")
    end
  end

  # Public: Package a theme using the theme packager.
  # The theme must be structured using valid JB API.
  # In other words packaging is essentially the reverse of installing.
  #
  # name - String, Required name of the theme you want to package.
  #        
  # Examples
  #
  #   rake theme:package name="twitter"
  #
  # Returns Success/failure messages.
  desc "Package theme"
  task :package do
    name = ENV["name"].to_s.downcase
    theme_path = JB::Path.build(:themes, :node => name)
    asset_path = JB::Path.build(:theme_assets, :node => name)

    abort("rake aborted: name cannot be blank") if name.empty?
    abort("rake aborted: '#{theme_path}' directory not found.") unless FileTest.directory?(theme_path)
    abort("rake aborted: '#{asset_path}' directory not found.") unless FileTest.directory?(asset_path)
    
    ## Mirror theme's template directory (_includes)
    packaged_theme_path = JB::Path.build(:themes, :root => JB::Path.build(:theme_packages, :node => name))
    mkdir_p packaged_theme_path
    cp_r theme_path, packaged_theme_path
    
    ## Mirror theme's asset directory
    packaged_theme_assets_path = JB::Path.build(:theme_assets, :root => JB::Path.build(:theme_packages, :node => name))
    mkdir_p packaged_theme_assets_path
    cp_r asset_path, packaged_theme_assets_path

    ## Log packager version
    packager = {"packager" => {"version" => CONFIG["theme_package_version"].to_s } }
    open(JB::Path.build(:theme_packages, :node => "#{name}/packager.yml"), "w") do |page|
      page.puts packager.to_yaml
    end
    
    puts "=> '#{name}' theme is packaged and available at: #{JB::Path.build(:theme_packages, :node => name)}"
  end
  
end # end namespace :theme

# Internal: Download and process a theme from a git url.
# Notice we don't know the name of the theme until we look it up in the manifest.
# So we'll have to change the folder name once we get the name.
#
# url - String, Required url to git repository.
#        
# Returns theme manifest hash
def theme_from_git_url(url)
  tmp_path = JB::Path.build(:theme_packages, :node => "_tmp")
  abort("rake aborted: system call to git clone failed") if !system("git clone #{url} #{tmp_path}")
  manifest = verify_manifest(tmp_path)
  new_path = JB::Path.build(:theme_packages, :node => manifest["name"])
  if File.exist?(new_path) && ask("=> #{new_path} theme package already exists. Override?", ['y', 'n']) == 'n'
    remove_dir(tmp_path)
    abort("rake aborted: '#{manifest["name"]}' already exists as theme package.")
  end

  remove_dir(new_path) if File.exist?(new_path)
  mv(tmp_path, new_path)
  manifest
end

# Internal: Process theme package manifest file.
#
# theme_path - String, Required. File path to theme package.
#        
# Returns theme manifest hash
def verify_manifest(theme_path)
  manifest_path = File.join(theme_path, "manifest.yml")
  manifest_file = File.open( manifest_path )
  abort("rake aborted: repo must contain valid manifest.yml") unless File.exist? manifest_file
  manifest = YAML.load( manifest_file )
  manifest_file.close
  manifest
end

def ask(message, valid_options)
  if valid_options
    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

#Load custom rake scripts
Dir['_rake/*.rake'].each { |r| load r }
