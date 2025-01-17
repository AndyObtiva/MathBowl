class MathBowling
  class ExcludableComposite
    include Glimmer::UI::CustomWidget

    body {
      composite(swt_style) {
        on_swt_hide {
          swt_widget.layoutData.exclude = true
        }
        on_swt_show {
          swt_widget.layoutData.exclude = false
        }
      }
    }

    def hide
      swt_widget.setVisible false
    end

    def show
      swt_widget.setVisible true
    end
  end
end
