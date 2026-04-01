depends() {
    echo systemd
    return 0
}

install() {
    inst_binary /usr/bin/vmtoolsd
    inst_binary /usr/bin/base64
    inst_binary /usr/bin/ign-converter
    inst_simple "${moddir}/ignition-convert.sh" "/usr/libexec/ignition-convert.sh"                                                                 
    inst_simple "${moddir}/ignition-convert.service" "${systemdsystemunitdir}/ignition-convert.service"
    $SYSTEMCTL -q --root "$initdir" add-wants cryptsetup.target ignition-convert.service
}