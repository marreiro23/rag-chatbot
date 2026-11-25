
echo gtk-marreiro-sounds=true


echo gtk-enable-event-sounds=true | tee -a $XDG_CONFIG_HOME/gtk-3.0/settings.ini
echo gtk-enable-input-feedback-sounds=true | tee -a $XDG_CONFIG_HOME/gtk-3.0/settings.ini
echo gtk-sound-theme-name=freedesktop | tee -a $XDG_CONFIG_HOME/gtk-3.0/settings.ini

HOME/.gtkrc-2.0 e $XDG_CONFIG_HOME/gtk-3.0/settings.ini

$XDG_CONFIG_HOME/gtk-3.0/settings.ini

cat <<'EOF' > $XDG_CONFIG_HOME/gtk-3.0/settings.ini
gtk-enable-event-sounds=true
gtk-enable-input-feedback-sounds=true
gtk-sound-theme-name=freedesktop
EOF






