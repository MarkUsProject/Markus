export const dark_mode_colors = {
  'primary_one': '#3b723e',
  'primary_two': '#336b88',
  'secondary_one': '#338104',
  'secondary_two': '#3393b5',
  'background_main': '#262626',
  'background_support': '#4e4e4e',
  'line': '#dddddd'
};
export const light_mode_colors = {
  'primary_one': '#3b723e',
  'primary_two': '#336b88',
  'secondary_one': '#338104',
  'secondary_two': '#3393b5',
  'background_main': '#262626',
  'background_support': '#4e4e4e',
  'line': '#000000'
};

export function switch_theme() {
  if (document.documentElement.style.getPropertyValue('--white') === '#fff') {
    document.documentElement.style.setProperty('--lighter-blue', dark_mode_colors["background_main"]);
    document.documentElement.style.setProperty('--white', dark_mode_colors["background_main"]);
    document.documentElement.style.setProperty('--light-blue', dark_mode_colors["background_support"]);
    document.documentElement.style.setProperty('--blue', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--dark-blue', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--sea-blue', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--navy', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--neon-navy', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--off-white', dark_mode_colors["background_main"]);
    document.documentElement.style.setProperty('--black', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--light-grey', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--grey', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--dark-grey', dark_mode_colors["primary_two"]);
    document.documentElement.style.setProperty('--light-red', dark_mode_colors["primary_two"]);
    document.documentElement.style.setProperty('--red', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--light-yellow', dark_mode_colors["primary_two"]);
    document.documentElement.style.setProperty('--yellow', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--mark-yellow', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--orange', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--darker-orange', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--lighter-green', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--light-green', dark_mode_colors["primary_one"]);
    document.documentElement.style.setProperty('--green', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--dark-green', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--disabled-grey', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--field-set-grey', dark_mode_colors["secondary_one"]);
    document.documentElement.style.setProperty('--disabled-dark', dark_mode_colors["secondary_one"]);

  } else {
    document.documentElement.style.setProperty('--white', '#fff');
    document.documentElement.style.setProperty('--light-grey', '#eee');
    document.documentElement.style.setProperty('--lighter-blue', '#e8f4f2');
  }
};
