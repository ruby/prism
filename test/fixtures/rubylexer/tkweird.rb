  WIDGET_DESTROY_HOOK = '<WIDGET_DESTROY_HOOK>'
  INTERP._invoke_without_enc('event', 'add', 
                             "<#{WIDGET_DESTROY_HOOK}>", '<Destroy>')
  INTERP._invoke_without_enc('bind', 'all', "<#{WIDGET_DESTROY_HOOK}>",
                             install_cmd(proc{|path|
                                unless TkCore::INTERP.deleted?
                                  begin
                                    if (widget=TkCore::INTERP.tk_windows[path])
                                      if widget.respond_to?(:__destroy_hook__)
                                        widget.__destroy_hook__
                                      end
                                    end
                                  rescue Exception=>e
                                      p e if $DEBUG
                                  end
                                end
                             }) << ' %W')



