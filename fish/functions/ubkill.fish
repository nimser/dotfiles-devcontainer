function ubkill --description 'restarts gpg-agent to force asking for PIN next time'
  command gpgconf --kill gpg-agent
end
