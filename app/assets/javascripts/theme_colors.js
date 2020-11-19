export const themes = {
  dark: {
    annotation_holder: '#48372c',
    background_main: '#161616',
    background_support: '#333d3e',
    comments_color: 'var(--heavy_success)',
    disabled: '#2b2b2b',
    error_light: '#a20000',
    heavy_alert: '#927c40',
    heavy_error: '#ff7575',
    heavy_success: '#b9e586',
    key_words_color: 'var(--primary_one)',
    light_alert: '#48372c',
    light_success: '#154100',
    line: '#b1b1b1',
    primary_one: '#67abfa',
    primary_two: '#243427',
    primary_three: '#75a278',
    sharp_line: '#e5e5e5',
    strings_color: 'var(--heavy_error)'
  },
  light: {
    annotation_holder: '#ffd452',
    background_main: '#fff',
    background_support: '#cee3ea',
    comments_color: 'var(--heavy_success)',
    disabled: '#bcbcbc',
    error_light: '#ffc2c2',
    heavy_alert: '#ffd452',
    heavy_error: '#a20000',
    heavy_success: '#246700',
    key_words_color: 'var(--primary_one)',
    light_alert: '#ffe9ac',
    light_success: '#b9e586',
    line: '#464646',
    primary_one: '#245185',
    primary_two: '#cee3ea',
    primary_three: '#4c7c51',
    sharp_line: '#000',
    strings_color: 'var(--heavy_error)',
  }
};

export function set_theme(theme) {
  if (theme === 'dark') {
    Object.keys(themes.dark).forEach(color => {
      document.documentElement.style.setProperty('--' + color, themes.dark[color]);
    });
  } else {
    Object.keys(themes.light).forEach(color => {
      document.documentElement.style.setProperty('--' + color, themes.light[color]);
    });
  }
}
