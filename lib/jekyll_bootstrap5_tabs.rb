# frozen_string_literal: true

require 'slim'
require_relative "jekyll_bootstrap5_tabs/version"

DEFAULT_TEMPLATE = 'template.slim'

module JekyllBootstrap5Tabs
  # Handles the outer {% tabs %}{% endtabs %} Liquid block for Bootstrap 5
  class TabsBlock < Liquid::Block
    def initialize(tag, args, _)
      super

      raise SyntaxError.new("#{tag} requires name") if args.empty?

      argv = args.strip.split ' '
      @tab_name = argv[0] # TODO @tab_name is never used. Should act as a namespace.

      # Set the pretty-print option for the Slim engine
      # Global configuration provides the default value of @pretty_print
      @pretty_print = false
      config = site.config['jekyll_bootstrap5_tabs']
      if not config.nil?
        config_pp = config['pretty_print']
        @pretty_print = not config_pp.nil? && config_pp == true
        puts "Bootstrap tab pretty-printing enabled by default for entire site."
      end
      # Usage can override default and enable pretty-printing, not possible to disable per-tab
      if argv.length>1 && argv[1].downcase == 'pretty'
        @pretty_print = true
        puts "Bootstrap tab pretty-printing enabled for {@tab_name}"
      end
    end

    def template_path(template_name)
      dir = File.dirname(__FILE__)
      File.join(dir, template_name.to_s)
    end

    def render(context)
      @environment = context.environments.first  # Has type Jekyll::Drops::UnifiedPayloadDrop
      #puts("TabsBlock.render: @environment = '#{@environment}'")
      super

      template_file_path = template_path(DEFAULT_TEMPLATE)
      Slim::Engine.set_options pretty: @pretty_print
      template = Slim::Template.new(template_file_path)
      template.render(self)
    end
  end

  # Handles the inner {% tab %}{% endtab %} Liquid block for Bootstrap 5
  class TabBlock < Liquid::Block
    def initialize(tag, args, _)
      super

      @tabs_group, @tab = split_params(args.strip)
      #puts("TabBlock: @tabs_group = '#{@tabs_group}', @tab = '#{@tab}'")
      raise SyntaxError.new("Block #{tag} requires tabs name") if @tabs_group.empty? || @tab.empty?
    end

    def render(context)
      content = super

      environment = context.environments.first # Has type Jekyll::Drops::UnifiedPayloadDrop
      environment["tabs-#{@tabs_group}"] ||= {}
      environment["tabs-#{@tabs_group}"][@tab] = content
    end

    private

    def split_params(params)
      params.split('#')
    end
  end
end

Liquid::Template.register_tag('tabs', JekyllBootstrap5Tabs::TabsBlock)
Liquid::Template.register_tag('tab', JekyllBootstrap5Tabs::TabBlock)
