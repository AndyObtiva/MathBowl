# Glimmer.logger.level = Logger::DEBUG

require_relative 'game_view'

module MathBowling
  class AppView
    FILE_PATH_IMAGE_MATH_BOWLING = "../../../../images/math-bowling.gif"
    include Glimmer

    include_package 'java.lang'

    attr_reader :games

    def initialize
      Display.setAppName('Math Bowling')
      Display.setAppVersion('1.0')
    end

    def build_game_view
      @game_view = math_bowling__game_view {
        @action_menu = menu(:drop_down) {
          menu_item(:push) {
            text "&Restart"
            on_widget_selected {
              @game_view.game.restart
              @game_view.show_question
            }
          }
          menu_item(:push) {
            text "&Quit"
            on_widget_selected {
              @game_view.hide
            }
          }
          if ENV['DEMO'].to_s.downcase == 'true'
            menu_item(:push) {
              text "&Demo"
              on_widget_selected {
                @game_view.game.demo
              }
            }
          end
        }
        menu_bar build_menu_bar {
          menu_item(:cascade) {
            text '&Action'
            menu @action_menu.swt_widget
          }
        }.swt_widget
        on_event_hide {
          render
        }
      }
    end

    def build_menu_bar(&more)
      @game_menu = menu(:drop_down) {
        4.times.map { |n|
          menu_item(:push) {
            text "&#{n+1} Player#{('s' unless n == 0)}"
            on_widget_selected {
              @game_type_container.hide
              @game_view.show(player_count: n+1)
            }
          }
        }
        menu_item(:push) {
          text "E&xit"
          on_widget_selected {
            exit(true)
          }
        }
      }
      menu(:bar) {
        default_item menu_item(:cascade) {
          text '&Game'
          menu @game_menu.swt_widget
        }.swt_widget
        more&.call
      }
    end

    def render
      if @game_type_container
        @initially_focused_widget.swt_widget.setFocus
        @game_type_container.show
      else
        @game_type_container = shell(:no_resize) {
          grid_layout {
            num_columns 1
            make_columns_equal_width true
            margin_width 35
            margin_height 35
          }
          background_image File.expand_path(FILE_PATH_IMAGE_MATH_BOWLING, __FILE__)
          text "Math Bowling"
          menu_bar build_menu_bar.swt_widget
          build_game_view
          label(:center) {
            layout_data :fill, :fill, true, true
            text "Math Bowling"
            font CONFIG[:title_font]
            foreground CONFIG[:title_foreground]
          }
          composite {
            fill_layout :horizontal
            layout_data :center, :center, true, true
            background :transparent
            @buttons = 4.times.map { |n|
              button {
                text "#{n+1} Player#{('s' unless n == 0)}"
                font CONFIG[:font]
                background CONFIG[:button_background]
                on_widget_selected {
                  @game_type_container.hide
                  @game_view.show(player_count: n+1)
                }
              }
            }
            @initially_focused_widget = @buttons.first
          }
          button {
            layout_data :center, :center, true, true
            text "Exit"
            font CONFIG[:font]
            background CONFIG[:button_background]
            on_widget_selected {
              exit(true)
            }
          }
        }
        @initially_focused_widget.swt_widget.setFocus
        @game_type_container.show
      end
    end
  end
end
