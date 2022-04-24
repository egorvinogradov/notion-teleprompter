function handleInitialLoad() {
  if (location.pathname === '/' && location.search.includes('start')) {
    alert('SHOW INTRO');
    location.search = '';
  }
}


function renderSettingsBlock(settings){
  const template = `
    <label>
      <input type="checkbox" checked name="mirrored"/>
      <span>Mirrored</span>
    </label>
    <label>
      <input type="checkbox" name="color_inverted"/>
      <span>Color Inverted</span>
    </label>
    <label>
      <input type="number" value="" name="font_size"/>
      <span>Font Size</span>
    </label>
  `;
  const settingsBlock = document.createElement('div');
  settingsBlock.classList.add('tele-settings');
  settingsBlock.innerHTML = template;

  document.body.insertBefore(settingsBlock, document.body.firstChild);

  const checkboxMirrored = document.querySelector('.tele-settings [name=mirrored]');
  const checkboxColorInverted = document.querySelector('.tele-settings [name=color_inverted]');
  const checkboxFontSize = document.querySelector('.tele-settings [name=font_size]');

  checkboxMirrored.checked = settings.mirrored;
  checkboxColorInverted.checked = settings.color_inverted;
  checkboxFontSize.value = settings.font_size;
}


function onSettingChange(e){
  const input = e.currentTarget;
  const key = input.name;
  let value;

  if (input.type === 'checkbox') {
    value = input.checked;
  }
  else {
    value = +input.value;
  }

  const updatedSettings = getLocalSettings();
  updatedSettings[key] = value;

  applySettings(updatedSettings);
  setLocalSettings(updatedSettings);
}


function applySettings(settings){
  document.body.classList.remove('tele_mirrored', 'tele_color_inverted');
  if (settings.mirrored) {
    document.body.classList.add('tele_mirrored');
  }
  if (settings.color_inverted) {
    document.body.classList.add('tele_color_inverted');
  }
  document.documentElement.style.setProperty('--tele-font-size', settings.font_size + 'px');
}


function getLocalSettings(){
  let localSettings = {};

  const DEFAULT_SETTINGS = {
    mirrored: false,
    color_inverted: true,
    font_size: 36,
  };

  try {
    localSettings = JSON.parse(localStorage.getItem('SETTINGS')) || {};
  }
  catch (e) {}
  return Object.assign({}, DEFAULT_SETTINGS, localSettings);
}


function setLocalSettings(value){
  localStorage.setItem('SETTINGS', JSON.stringify(value || {}));
}



/**
 * INITIALIZATION
 */

document.addEventListener('DOMContentLoaded', () => {
  const currentSettings = getLocalSettings();

  handleInitialLoad();
  applySettings(currentSettings);
  renderSettingsBlock(currentSettings);

  document.querySelectorAll('.tele-settings input').forEach(function(element){
    element.addEventListener('change', onSettingChange);
  });
});
