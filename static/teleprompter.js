window.TP = window.TP || {};

/**
 * 1. Line height
 * 2. Left paddings
 * 3. Header font sizes
 * 4. Fixed panel
 * ✅ 5. Babel compile for iOS 10
 * 6. Hide presenter panel on host machine
 * ✅ 7. npm start in launch.sh
 * 8. Panel should always stick to left side
 * 9. Auto scroll mode?
 * 10. Update readme
 * 11. Intro screen "Open <IP_ADDRESS:7777>"
 */


class Presenter {

  CLASSNAME_PANEL = 'teleprompter-panel';
  CLASSNAME_MIRRORED = 'teleprompter--mirrored';
  CLASSNAME_COLORS_INVERTED = 'teleprompter--colors-inverted';

  DEFAULT_SETTINGS = {
    mirrored: false,
    fontSize: 36,
    colorsInverted: true,
  };

  /**
   * @type {function}
   */
  onSettingsChangeCallback = null;

  /**
   * @type {HTMLElement}
   */
  panel = null;

  initialize = () => {
    const settings = this.getCurrentSettings();

    this.panel = this.renderPanel();

    this.setPanelValue(settings);
    this.applySettings(settings);

    this.panel.querySelectorAll('input').forEach(input => {
      input.addEventListener('change', this.onInputChange);
    });
  };

  onSettingsChange = (callback) => {
    this.onSettingsChangeCallback = callback;
  };

  renderPanel = () => {
    const template = `
      <label>
        <input type="checkbox" checked name="mirrored"/>
        <span>Mirrored</span>
      </label>
      <label>
        <input type="checkbox" name="colorsInverted"/>
        <span>Colors Inverted</span>
      </label>
      <label>
        <input type="number" value="" name="fontSize"/>
        <span>Font Size</span>
      </label>
    `;
    const panel = document.createElement('div');
    panel.classList.add(this.CLASSNAME_PANEL);
    panel.innerHTML = template;

    document.body.insertBefore(panel, document.body.firstChild);
    return panel;
  };

  setPanelValue = (settings) => {
    const { mirrored, colorsInverted, fontSize } = settings;
    if (typeof mirrored !== 'undefined') {
      this.panel.querySelector('input[name=mirrored]').checked = mirrored;
    }
    if (typeof colorsInverted !== 'undefined') {
      this.panel.querySelector('input[name=colorsInverted]').checked = colorsInverted;
    }
    if (typeof fontSize !== 'undefined') {
      this.panel.querySelector('input[name=fontSize]').value = fontSize;
    }
  };

  applySettings = (settings) => {
    const { mirrored, colorsInverted, fontSize } = settings;
    document.body.classList.remove(this.CLASSNAME_MIRRORED, this.CLASSNAME_COLORS_INVERTED);
    if (mirrored) {
      document.body.classList.add(this.CLASSNAME_MIRRORED);
    }
    if (colorsInverted) {
      document.body.classList.add(this.CLASSNAME_COLORS_INVERTED);
    }
    document.documentElement.style.setProperty('--tele-font-size', fontSize + 'px');
  };

  onInputChange = (e) => {
    const input = e.currentTarget;
    const key = input.name;
    let value;

    if (input.type === 'checkbox') {
      value = input.checked;
    }
    else {
      value = +input.value;
    }

    const updatedSettings = this.getCurrentSettings();
    updatedSettings[key] = value;

    this.applySettings(updatedSettings);
    this.setCurrentSettings(updatedSettings);

    if (this.onSettingsChangeCallback) {
      this.onSettingsChangeCallback(updatedSettings);
    }
  };

  getCurrentSettings = () => {
    let localSettings = {};
    try {
      localSettings = JSON.parse(localStorage.getItem('SETTINGS')) || {};
    }
    catch (e) {}
    return {
      ...this.DEFAULT_SETTINGS,
      ...localSettings,
    };
  };

  setCurrentSettings = (value) => {
    localStorage.setItem('SETTINGS', JSON.stringify(value || {}));
  }
}



class Sync {

  SYNC_SERVER_URL = 'http://' + location.hostname + ':8080';

  /**
   * @type {Presenter}
   */
  presenter = null;

  constructor(options){
    const { presenter } = options;
    this.presenter = presenter;
  }

  sendCommand = (command) => {
    this.socket.emit('message', command);
  };

  executeCommand = (command) => {
    console.log('EXEC', command);
    const { type, pathname, scrollRatio, settings } = command;

    if (type === 'navigate') {
      location.pathname = pathname;
    }
    else if (type === 'scroll') {
      const scrollHeight = (document.body.scrollHeight - innerHeight) * scrollRatio;
      window.scrollTo(0, scrollHeight);
    }
    else if (type === 'settings_change') {
      this.presenter.setPanelValue(settings);
      this.presenter.applySettings(settings);
      this.presenter.setCurrentSettings(settings);
    }
  };

  getDeviceRole = () => {
    return location.hostname === 'localhost' ? 'host' : 'teleprompter';
  };

  onPageScroll = () => {
    const { scrollTop, scrollHeight } = document.body;
    const scrollRatio = scrollTop / (scrollHeight - innerHeight);
    this.sendCommand({
      type: 'scroll',
      scrollRatio,
    });
  };

  parseQueryParams = () => {
    const params = {};
    location.search.replace(/^\?/, '').split('&').forEach(param => {
      const [key, value] = param.split('=');
      params[key] = value;
    });
    return params;
  };

  showGettingStartedMessage = () => {
    alert('Get started!');
  };

  initialize = () => {
    const pathname = decodeURIComponent(location.pathname);

    this.socket = io(this.SYNC_SERVER_URL);

    const params = this.parseQueryParams();
    if (params.start) {
      this.showGettingStartedMessage();
      history.replaceState({}, '', pathname)
    }

    if (this.getDeviceRole() === 'host') {
      this.sendCommand({
        type: 'navigate',
        pathname,
      });
      this.presenter.onSettingsChange(settings => {
        this.sendCommand({
          type: 'settings_change',
          settings,
        });
      });
      window.addEventListener('scroll', this.onPageScroll);
    }
    else {
      this.socket.on('message', this.executeCommand);
    }
  }
}



document.addEventListener('DOMContentLoaded', () => {
  const presenter = new Presenter();
  presenter.initialize();

  const sync = new Sync({ presenter });
  sync.initialize();

  window.TP.sync = sync;
});
