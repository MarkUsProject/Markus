export const themes = {
  dark: {
    annotation_holder: '#48372c',
    active_menu: 'var(--sharp_line)',
    background_main: '#161616',
    background_support: '#333d3e',
    comments_color: 'var(--severe_success)',
    disabled_text: '#9f9f9f',
    disabled_area: '#2b2b2b',
    gridline: '#b1b1b140',
    key_words_color: 'var(--primary_one)',
    light_alert: '#48372c',
    light_error: '#a20000',
    light_success: '#154100',
    line: '#b1b1b1',
    primary_one: '#98c7ff',
    primary_two: '#243427',
    primary_three: '#75a278',
    severe_alert: '#927c40',
    severe_error: '#ff7575',
    severe_success: '#b9e586',
    sharp_line: '#e5e5e5',
    strings_color: 'var(--severe_error)',
    sub_menu: '#1b426d'
  },
  light: {
    annotation_holder: '#ffd452',
    active_menu: 'var(--background_main)',
    background_main: '#fff',
    background_support: '#e8f4f2',
    comments_color: 'var(--severe_success)',
    disabled_text: '#b5b5b5',
    disabled_area: '#bcbcbc',
    gridline: '#46464640',
    key_words_color: 'var(--primary_one)',
    light_alert: '#ffe9ac',
    light_error: '#ffc2c2',
    light_success: '#b9e586',
    line: '#464646',
    primary_one: '#245185',
    primary_two: '#cee3ea',
    primary_three: '#89b1dd',
    severe_alert: '#ffd452',
    severe_error: '#a20000',
    severe_success: '#246700',
    sharp_line: '#000',
    strings_color: 'var(--severe_error)',
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
