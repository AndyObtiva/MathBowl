require_relative 'score_board_view'

using ArrayIncludeMethods

class MathBowling
  class GameView
    include Glimmer::UI::CustomShell

    FILE_IMAGE_BACKGROUND = "../../../../images/math-bowling-background.jpg"
    
    TIMER_DURATION_DISABLED = 86400 # stop timer temporarily by setting to a very high value
    TIMER_DURATION_ADD_SUBTRACT = 15
    TIMER_DURATION_MULTIPLY_DIVIDE = 30

    attr_accessor :question_container, :can_change_names,
                  :answer_result_announcement, :answer_result_announcement_background,
                  :timer, :roll_button_text, :video_playing_time, :showing_next_player
    attr_reader :game

    before_body {
      @game = MathBowling::Game.new
      @font = CONFIG[:frame_font]
      @font_button = CONFIG[:button_font]
      @answer_result_announcement = "\n" # to take correct multi-line size
      @mutex = Mutex.new
      observe(@game, :roll_done) do |roll_done|
        if roll_done
          if @game.over?
            @restart_button.swt_widget.setFocus
          else
            @answer_text.swt_widget.setFocus
          end
        end
      end
      observe(@game, :answer_result) do |answer_result|
        @answer_text.swt_widget.setFocus if answer_result.nil?
      end
    }

    after_body {
      handle_answer_result_announcement
      set_timer
      handle_roll_button_text
      register_can_change_names
      register_video_events
    }

    body {
      shell(:no_resize) {
        @background = :transparent
        @foreground = :black
        text CONFIG[:game_title]
        background_image File.expand_path(FILE_IMAGE_BACKGROUND, __FILE__)
        image APP_ICON if OS.windows?
        on_swt_show {
          @saved_timer = nil
          if @game.player_count == 1
            @game.start if @game.not_started?
            show_question
          else
            show_name_form
          end          
          body_root.pack
          focus_default_widget
        }
        on_swt_hide {
          show_question # stops videos if still running
          @game.quit
        }
        composite {
          composite {
            grid_layout 1, false
            background @background
            Game::PLAYER_COUNT_MAX.times.map { |player_index|
              score_board_view(game: @game, player_index: player_index) {
                layout_data {
                  horizontal_alignment :fill
                  grab_excess_horizontal_space true
                  exclude bind(@game, :player_count) { |player_count| player_index >= player_count.to_i }
                }
              }
            }
          }
          background @background
          composite {
            grid_layout 1, false
            layout_data(:fill, :fill, true, true)
            background @background
            @question_container = composite {
              layout_data {
                horizontal_alignment :center
                vertical_alignment :center
                grab_excess_horizontal_space true
                minimum_height(450) if OS.windows?
              }
              row_layout {
                type :vertical
                fill true
                spacing 6
              }
              background @background
              on_key_pressed {|key_event|
                show_next_player if @video_playing_time && !@showing_next_player
              }
              on_focus_gained {
                focus_default_widget
              }
              # Intentionally pre-initializing video widgets for all videos to avoid initial loading time upon playing a video (trading memory for speed)
              @videos_by_answer_result_and_pin_state = VideoRepository.index_by_answer_result_and_pin_state do |answer_result, pin_state|
                VideoRepository.video_paths_by_answer_result_and_pin_state[answer_result][pin_state].map do |video_path|
                  video(file: video_path, autoplay: false, controls: false, fit_to_height: false, offset_x: -80, offset_y: -100) { |video|
                    layout_data {
                      exclude true
                      width 0
                      height 0
                    }
                    visible false
                    on_mouse_down {
                      show_next_player if @video_playing_time && !@showing_next_player
                    }
                    on_ended {
                      show_next_player if @video_playing_time && !@showing_next_player
                    }
                    on_playing {
                      video_playing_time = self.video_playing_time = Time.now
                      Thread.new {
                        sleep(5)
                        if video_playing_time == self.video_playing_time
                          async_exec {
                            show_next_player if !@showing_next_player
                          }
                        end
                      }
                    }
                  }                  
                end
              end
              @answer_result_announcement_label = label(:center) {
                background bind(self, 'answer_result_announcement_background')
                text bind(self, 'answer_result_announcement')
                visible bind(@game, 'answer_result')
                font CONFIG[:answer_result_announcement_font]
                layout_data { exclude false }
              }
              label(:center) {
                background CONFIG[:button_background]
                text bind(@game, 'current_player.score_sheet.current_frame.remaining_pins') {|pins| "#{pins} PIN#{'S' if pins != 1} LEFT"}
                font CONFIG[:frame_font]
                layout_data { exclude false }
              }
              @math_question_container = composite {
                background @background
                layout_data { exclude false }
                grid_layout(1, false) {
                  margin_width 0
                  vertical_spacing 0
                }
                label(:center) {
                  background bind(self, :player_color, computed_by: "game.current_player.index")
                  foreground :yellow
                  text bind(@game, "question") {|question| "#{question} = ?" }
                  font @font
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                  }
                }
              }
              @answer_text = text(:center, :border) {
                focus true
                text bind(@game, "answer")
                font @font
                enabled bind(self, "game.in_progress?", computed_by: ["game.current_player" ,"game.current_player.score_sheet.current_frame"])
                layout_data { exclude false }
                on_key_pressed {|key_event|
                  @game.roll if key_event.keyCode == swt(:cr)
                }
                on_verify_text {|verify_event|
                  final_text = "#{@answer_text.swt_widget.getText}#{verify_event.text}"
                  verify_event.doit = !!final_text.match(/^[0-9]{0,3}$/)
                }
              }
              button(:center) {
                text bind(self, :roll_button_text)
                layout_data {
                  height 42
                }
                font @font_button
                background bind(self, :player_color, computed_by: "game.current_player.index")
                foreground :yellow
                enabled bind(self, "game.in_progress?", computed_by: ["game.current_player" ,"game.current_player.score_sheet.current_frame"])
                on_widget_selected {
                  @game.roll
                }
                on_key_pressed {|key_event|
                  @game.roll if key_event.keyCode == swt(:cr)
                }
              }
              @name_form_container = composite {
                grid_layout(1, false) {
                  margin_width 0
                  margin_height 0
                  vertical_spacing 10
                }
                layout_data {
                  exclude true
                }
                visible false
                background @background
                composite {
                  background @background
                  layout_data { exclude false }
                  grid_layout(1, false) {
                    margin_width 0
                    vertical_spacing 0
                  }
                  label(:center) {
                    background bind(self, :name_player_color, computed_by: "game.name_current_player.index")
                    foreground :yellow
                    text bind(@game, 'name_current_player.index') {|i| "Player #{i.to_i+1} - Please Enter Your Name" }
                    font @font
                    layout_data {
                      horizontal_alignment :fill
                      vertical_alignment :center
                      minimum_width 630
                      minimum_height CONFIG[:label_button_minimum_height]
                      grab_excess_horizontal_space true
                    }
                  }
                }
                @name_text = text(:center, :border) {
                  focus true
                  text bind(@game, "name_current_player.name")
                  font @font
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                  }
                  on_key_pressed {|key_event|
                    enter_name if key_event.keyCode == swt(:cr)
                  }
                  on_verify_text {|verify_event|
                    final_text = "#{@name_text.swt_widget.getText}#{verify_event.text}"
                    verify_event.doit = final_text.size <= 6
                  }
                }
                @enter_name_button = button(:center) {
                  focus true
                  text 'Enter Name'
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                    height_hint 42
                  }
#                   enabled bind(@game, 'name_current_player.name') { |name| !name.to_s.empty? } # disabled because it looks ugly
                  font @font_button
                  background bind(self, :name_player_color, computed_by: "game.name_current_player.index")
                  foreground :yellow
                  on_widget_selected {
                    enter_name
                  }
                  on_key_pressed {|key_event|
                    enter_name if key_event.keyCode == swt(:cr)
                  }
                }
              }
              @next_player_announcement_container = composite {
                grid_layout(1, false) {
                  margin_width 0
                  margin_height 0
                  vertical_spacing 0
                }
                layout_data {
                  exclude true
                }
                visible false
                background @background
                composite {
                  grid_layout(1, false) {
                    margin_top 0
                    margin_bottom 5
                  }
                  layout_data {
                    horizontal_alignment :fill
                    grab_excess_horizontal_space true
                  }
                  background bind(self, :player_color, computed_by: "game.current_player.index")
                  label(:center) {
                    background bind(self, :player_color, computed_by: "game.current_player.index")
                    foreground :yellow
                    text bind(@game, 'current_player.name') { |player_name| "#{player_name}," }
                    font CONFIG[:scoreboard_total_font]
                    layout_data {
                      horizontal_alignment :fill
                      vertical_alignment :center
                      minimum_width 630
                      minimum_height CONFIG[:label_button_minimum_height]
                      grab_excess_horizontal_space true
                    }
                  }
                  label(:center) {
                    background bind(self, :player_color, computed_by: "game.current_player.index")
                    foreground :yellow
                    text 'Get Ready!'
                    font CONFIG[:frame_font]
                    layout_data {
                      horizontal_alignment :fill
                      vertical_alignment :center
                      minimum_width 630
                      minimum_height CONFIG[:label_button_minimum_height]
                      grab_excess_horizontal_space true
                    }
                  }
                }
                composite {
                  grid_layout(1, false) {
                    margin_width 0
                    margin_height 10
                  }
                  layout_data {
                    horizontal_alignment :fill
                    grab_excess_horizontal_space true
                  }
                  background @background
                  @continue_button = button(:center) {
                    layout_data {
                      horizontal_alignment :fill
                      grab_excess_horizontal_space true
                      height_hint 42
                    }
                    text 'Continue'
                    background CONFIG[:button_background]
                    font @font_button
                    on_widget_selected {
                      show_question
                    }
                    on_key_pressed {|key_event|
                      show_question if key_event.keyCode == swt(:cr)
                    }
                  }
                }
              }
              @game_over_announcement_container = composite {
                grid_layout(1, false) {
                  margin_width 0
                  margin_top 0
                  margin_bottom 5
                  vertical_spacing 0
                }
                layout_data {
                  exclude true
                }
                visible false
                background bind(self, :winner_color, computed_by: "game.current_player.index")
                label(:center) {
                  background bind(self, :winner_color, computed_by: "game.current_player.index")
                  foreground :white
                  text 'GAME OVER'
                  font CONFIG[:scoreboard_total_font]
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                  }
                }
                label(:center) {
                  background bind(self, :winner_color, computed_by: "game.current_player.index")
                  foreground :yellow
                  text bind(self, 'game.status', computed_by: ["game.current_player" ,"game.current_player.score_sheet.current_frame"]) {|s| "#{'Winner ' if @game.player_count.to_i > 1}Score: #{@game.winner_total_score}" }
                  font CONFIG[:frame_font]
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                  }
                }
                label(:center) {
                  background bind(self, :winner_color, computed_by: "game.current_player.index")
                  foreground :yellow
                  text bind(self, 'game.status', computed_by: ["game.current_player" ,"game.current_player.score_sheet.current_frame"]) {|s| "Winner#{'s' if @game.winners.size > 1}: #{@game.winners.map(&:name).join(" / ")}" }
                  font CONFIG[:frame_font]
                  visible bind(@game, :player_count, read_only: true) {|pc| pc.to_i > 1}
                  layout_data {
                    horizontal_alignment :fill
                    vertical_alignment :center
                    minimum_width 630
                    minimum_height CONFIG[:label_button_minimum_height]
                    grab_excess_horizontal_space true
                  }
                }
              }
            }
          }
          composite {
            fill_layout(:horizontal) {
              spacing 15
            }
            layout_data :center, :center, true, true
            background @background
            @restart_button = button {
              background CONFIG[:button_background]
              text "&Restart Game"
              font CONFIG[:font]
              enabled bind(@game, :name_current_player, on_read: :!)
              on_widget_selected {
                @game.restart
                show_next_player
              }
            }
            button {
              background CONFIG[:button_background]
              text "&Back To Main Menu"
              font CONFIG[:font]
              on_widget_selected {
                hide
              }
            }
            button {
              background CONFIG[:button_background]
              text "&Quit"
              font CONFIG[:font]
              on_widget_selected {
                exit(true)
              }
            }
            if ENV['DEMO'].to_s.downcase == 'true'
              button {
                background CONFIG[:button_background]
                text "&Demo"
                enabled bind(self, "game.in_progress?", computed_by: ["game.current_player" ,"game.current_player.score_sheet.current_frame"])
                font CONFIG[:font]
                on_widget_selected {
                  @game.demo
                }
              }
            end
          }
        }
      }
    }

    def player_count=(value)
      @game.player_count = value
      @player_count = value
    end

    def handle_answer_result_announcement
      observe(@game, :answer_result) do
        if @game.answer_result
          @last_answer = @game.answer
          new_answer_result_announcement = ''

          if @game.answer_result == 'CLOSE'
            new_answer_result_announcement += "Nice try! "
          elsif @game.answer_result == 'CORRECT'
            if @game.current_player.score_sheet.current_frame.triple_strike?
              new_answer_result_announcement += "Triple Strike! "
            elsif @game.current_player.score_sheet.current_frame.double_strike?
              new_answer_result_announcement += "Double Strike! "
            elsif @game.current_player.score_sheet.current_frame.strike?
              new_answer_result_announcement += "Strike! "
            elsif @game.current_player.score_sheet.current_frame.spare?
              new_answer_result_announcement += "Spare! "
            else
              new_answer_result_announcement += "Great job! "
            end
          end
          remaining_pin_prefix = nil
          if @game.fallen_pins == @game.remaining_pins
            if @game.fallen_pins == 1
              remaining_pin_prefix = 'The'
            else
              remaining_pin_prefix = 'All'
            end
          else
            remaining_pin_prefix = "#{@game.fallen_pins} of"
          end
          new_answer_result_announcement += "#{remaining_pin_prefix} #{@game.remaining_pins}#{' remaining' if @game.remaining_pins < 10} pin#{'s' if @game.remaining_pins != 1} #{@game.fallen_pins != 1 ? 'were' : 'was'} knocked down!"
#           answer_and_correct_answer = [@last_answer.to_i, @game.correct_answer.to_i]
#           fallen_pins_calculation = " Calculation: #{@game.remaining_pins} - (#{answer_and_correct_answer.max} - #{answer_and_correct_answer.min})"
#           new_answer_result_announcement += fallen_pins_calculation

          new_answer_result_announcement += "\n"

          new_answer_result_announcement += "The answer #{@game.answer.to_i} to #{@game.question} was #{@game.answer_result}!"
          if @game.answer_result != 'CORRECT'
            new_answer_result_announcement += " The correct answer is #{@game.correct_answer.to_i}."
          end

          self.answer_result_announcement = new_answer_result_announcement
          self.answer_result_announcement_background = case @game.answer_result
          when 'CORRECT'
            :green
          when 'WRONG'
            :red
          when 'CLOSE'
            :yellow
          end
        else
          self.answer_result_announcement = "\n" # to take correct multi-line size
          self.answer_result_announcement_background = :transparent
        end
      end
    end

    def timer_duration
      %w[+ -].include?(@game.operator) || %w[+ -].include_all?(@game.math_operations) ? TIMER_DURATION_ADD_SUBTRACT : TIMER_DURATION_MULTIPLY_DIVIDE
    end

    def set_timer
      timer_thread = Thread.new do
        loop do
          sleep(1)
          @game.started? && body_root && async_exec do
            self.timer = self.timer - 1 if self.timer && self.timer > 0
            if self.timer == 0
              @game.roll
            end
          end
        end
      end
      observe(@game, :question) do |new_question|
        self.timer = timer_duration
      end
    end

    def handle_roll_button_text
      observe(self, :timer) do
        if @game.in_progress?
          self.roll_button_text = "Enter Answer (#{self.timer} seconds left)"
          # disabled because it doesn't look good
#           if @game.player_count.to_i > 1
#             self.roll_button_text = "#{@game.current_player.name} - #{self.roll_button_text}"
#           end
        end
      end
    end

    def register_video_events
      observe(@game, :answer_result) do |new_answer_result|
        show_video if new_answer_result
      end
    end

    def show_video
      new_answer_result = @game.answer_result
      new_pin_state = @game.remaining_pins == 10 ? 'full' : 'partial'
      videos = @videos_by_answer_result_and_pin_state[new_answer_result][new_pin_state]
      @video = videos[(rand*videos.size).to_i]
      @video.play
      @video.swt_widget.setLayoutData RowData.new
      @video.swt_widget.getLayoutData.width = @question_container.swt_widget.getSize.x
      @video.swt_widget.getLayoutData.height = @question_container.swt_widget.getSize.y
      @question_container.swt_widget.getChildren.each do |child|
        child.getLayoutData.exclude = true
        child.setVisible(false)
      end
      @video.swt_widget.getLayoutData.exclude = false
      @video.swt_widget.setVisible(true)
      @game_over_announcement_container.swt_widget.getLayoutData&.exclude = true
      @game_over_announcement_container.swt_widget.setVisible(false)
      @question_container.swt_widget.pack
    end

    def all_videos
      @all_videos ||= @videos_by_answer_result_and_pin_state.values.map(&:values).flatten
    end

    def show_next_player      
      self.video_playing_time = nil
      if @game.in_progress? && (@game.player_count > 1)
        @saved_timer = timer_duration
        self.timer = TIMER_DURATION_DISABLED
        @showing_next_player = true
        @question_container.swt_widget.getChildren.each do |child|
          child.getLayoutData.exclude = true
          child.setVisible(false)
        end
        @answer_result_announcement_label.swt_widget.setVisible(true)
        @answer_result_announcement_label.swt_widget.getLayoutData&.exclude = false
        @next_player_announcement_container.swt_widget.getLayoutData.exclude = false
        @next_player_announcement_container.swt_widget.setVisible(true)
        OS.mac? ? @question_container.swt_widget.pack : body_root.pack
        focus_default_widget
      else
        show_question
      end
    end

    def show_question
      @showing_next_player = false
      self.video_playing_time = nil
      all_videos.each do |video|
        video.pause
        video.position = 0
      end
      if @game.in_progress?
        @question_container.swt_widget.getChildren.each do |child|
          child.setVisible(true)
          child.getLayoutData&.exclude = false
        end        
      end
      @answer_result_announcement_label.swt_widget.setVisible(true)
      @answer_result_announcement_label.swt_widget.getLayoutData&.exclude = false
      @next_player_announcement_container.swt_widget.setVisible(false)
      @next_player_announcement_container.swt_widget.getLayoutData&.exclude = true
      @game_over_announcement_container.swt_widget.setVisible(false)
      @game_over_announcement_container.swt_widget.getLayoutData&.exclude = true
      @name_form_container.swt_widget.setVisible(false)
      @name_form_container.swt_widget.getLayoutData&.exclude = true #TODO check if this is even needed 
      all_videos.each do |video|
        video.swt_widget&.getLayoutData&.exclude = true
        video.swt_widget&.setVisible(false)
      end
      if @game.not_in_progress?
        @game_over_announcement_container.swt_widget.setVisible(true)
        @game_over_announcement_container.swt_widget.getLayoutData&.exclude = false
      end
      OS.mac? || @game.player_count > 1 ? @question_container.swt_widget.pack : body_root.pack
      if @game.in_progress?
        focus_default_widget
        if @saved_timer
          self.timer = @saved_timer
          @saved_timer = nil
        else
          self.timer = timer_duration
        end
      end
    end

    def show_name_form
      @saved_timer = self.timer if self.timer <= timer_duration
      self.timer = TIMER_DURATION_DISABLED
      @game.current_players.each {|player| player.name = nil}
      @game.name_current_player = @game.current_players.first
      @question_container.swt_widget.getChildren.each do |child|
        child.getLayoutData.exclude = true
        child.setVisible(false)
      end
      @name_form_container.swt_widget.setVisible(true)
      @name_form_container.swt_widget.getLayoutData&.exclude = false
      body_root.pack
      focus_name_form
    end

    def enter_name
      return if @game.name_current_player.name.to_s.strip.empty? || @game.current_players.map(&:name).count(@game.name_current_player.name) > 1
      name_current_player_index = @game.name_current_player.index
      @game.switch_name_player
      if name_current_player_index < (@game.player_count - 1)
        focus_name_form
      else
        @game.name_current_player = nil
        @game.start if @game.not_started?
        show_question
        body_root.pack
        @answer_text.swt_widget.setFocus
      end
    end

    def focus_name_form
      @name_text.swt_widget.setFocus
    end

    def focus_default_widget
      Thread.new do      
        sleep(0.25)
        @mutex.synchronize do
          async_exec do
            if @name_form_container&.swt_widget&.isVisible
              focus_name_form
            elsif @continue_button&.swt_widget&.isVisible
              @continue_button.swt_widget.setFocus
            else
              @answer_text&.swt_widget&.setFocus
            end
          end
        end
      end
    end

    def register_can_change_names
      handle_can_change_names = lambda do |value|
        self.can_change_names = @game.player_count.to_i > 1 && !video_playing_time
      end
      observe(@game, :player_count, &handle_can_change_names)
      observe(self, :video_playing_time, &handle_can_change_names)
    end

    def player_color
      if @game.current_player.nil?
        CONFIG[:colors][:player1]
      else
        (@game.current_player.index % 2) == 0 ? CONFIG[:colors][:player1] : CONFIG[:colors][:player2]
      end
    end

    def name_player_color
      if @game.name_current_player.nil?
        CONFIG[:colors][:player1]
      else
        (@game.name_current_player.index % 2) == 0 ? CONFIG[:colors][:player1] : CONFIG[:colors][:player2]
      end
    end

    def winner_color
      (@game.winner&.index.to_i % 2) == 0 ? CONFIG[:colors][:player1] : CONFIG[:colors][:player2]
    end

    def show(player_count: 1, difficulty: :medium, math_operation: 'all')
      @game.quit
      @game.player_count = player_count
      @game.difficulty = difficulty
      @game.math_operation = math_operation
      super()
    end
  end
end
