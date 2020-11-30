export const themes = {
  dark: {
    annotation_holder: '#48372c',
    background_main: '#161616',
    background_support: '#333d3e',
    comments_color: 'var(--heavy_success)',
    disabled_text: '#9f9f9f',
    disabled_area: '#2b2b2b',
    error_light: '#a20000',
    gridline: '#b1b1b140',
    heavy_alert: '#927c40',
    heavy_error: '#ff7575',
    heavy_success: '#b9e586',
    key_words_color: 'var(--primary_one)',
    light_alert: '#48372c',
    light_success: '#154100',
    line: '#b1b1b1',
    primary_one: '#98c7ff',
    primary_two: '#243427',
    primary_three: '#75a278',
    sharp_line: '#e5e5e5',
    strings_color: 'var(--heavy_error)',
    sub_menu: '#1b426d'
  },
  light: {
    annotation_holder: '#ffd452',
    background_main: '#fff',
    background_support: '#e8f4f2',
    comments_color: 'var(--heavy_success)',
    disabled_text: '#b5b5b5',
    disabled_area: '#bcbcbc',
    error_light: '#ffc2c2',
    gridline: '#46464640',
    heavy_alert: '#ffd452',
    heavy_error: '#a20000',
    heavy_success: '#246700',
    key_words_color: 'var(--primary_one)',
    light_alert: '#ffe9ac',
    light_success: '#b9e586',
    line: '#464646',
    primary_one: '#245185',
    primary_two: '#cee3ea',
    primary_three: '#89b1dd',
    sharp_line: '#000',
    strings_color: 'var(--heavy_error)',
    sub_menu: 'var(--primary_three)'
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
