# Macchina di prova per dattilo: Arch con quello che serve, un utente normale, niente rete esterna a runtime.
FROM archlinux:latest
RUN pacman -Syu --noconfirm --needed neovim nodejs gcc tmux curl python bubblewrap && pacman -Scc --noconfirm
RUN useradd -m -s /bin/bash utente
USER utente
WORKDIR /home/utente
ENV LANG=C.UTF-8 TERM=xterm-256color
