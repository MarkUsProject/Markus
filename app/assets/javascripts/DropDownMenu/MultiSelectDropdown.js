import React, {useState} from "react";

export const MultiSelectDropdown = ({data}) => {
  const [selected, setSelected] = useState([]);

  const toggleOption = ({id}) => {
    setSelected(prevSelected => {
      // if it's in, remove
      const newArray = [...prevSelected];
      if (newArray.includes(id)) {
        return newArray.filter(item => item !== id);
        // else, add
      } else {
        newArray.push(id);
        return newArray;
      }
    });
  };

  return <Selector options={data} selected={selected} toggleOption={toggleOption} />;
};

const Selector = ({options, selected, toggleOption}) => {
  return (
    <div className="dropdown">
      <div className="c-multi-select-dropdown__selected">
        <div>{selected.length} selected</div>
      </div>
      <ul className="c-multi-select-dropdown__options">
        {options.map(option => {
          const isSelected = selected.includes(option.id);

          return (
            <li
              className="c-multi-select-dropdown__option"
              onClick={() => toggleOption({id: option.id})}
            >
              <input
                type="checkbox"
                checked={isSelected}
                className="c-multi-select-dropdown__option-checkbox"
              ></input>
              <span>{option.title}</span>
            </li>
          );
        })}
      </ul>
    </div>
  );
};
