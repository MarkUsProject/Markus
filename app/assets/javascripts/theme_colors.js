export const dark_mode_colors = {
  'primary_one': '#bc64be',
  'primary_two': '#5b37ea',
  'secondary_one': '#69964f',
  'secondary_two': '#176c92',
  'background_main': '#212121',
  'background_support': '#484848',
  'line': '#9b9b9b'
};
export const light_mode_colors = {
  'primary_one': '#6b3f6b',
  'primary_two': '#483888',
  'secondary_one': '#335f18',
  'secondary_two': '#38697c',
  'background_main': '#e0e0e0',
  'background_support': '#a2a2a2',
  'line': '#1a1a1a'
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
