ARCH=$(uname -m)
if [ "$ARCH" = "i486" ]; then
  LIBDIRSUFFIX=""
elif [ "$ARCH" = "i686" ]; then
  LIBDIRSUFFIX=""
elif [ "$ARCH" = "x86_64" ]; then
  LIBDIRSUFFIX="64"
else
  LIBDIRSUFFIX=""
fi

if [ -x /usr/bin/update-desktop-database ]; then
  /usr/bin/update-desktop-database -q usr/share/applications >/dev/null 2>&1
fi

if [ -e usr/share/icons/hicolor/icon-theme.cache ]; then
  if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache usr/share/icons/hicolor >/dev/null 2>&1
  fi
fi

if [ ! -r /lib${LIBDIRSUFFIX}/libudev.so.1 ]; then
  ( cd lib${LIBDIRSUFFIX}; rm -rf libudev.so.1 )
  ( cd lib${LIBDIRSUFFIX}; ln -sf libudev.so.0 libudev.so.1 )
fi
( cd usr/bin; rm -rf Popcorn-Time )
( cd usr/bin; ln -sf /opt/Popcorn-Time/Popcorn-Time Popcorn-Time )
