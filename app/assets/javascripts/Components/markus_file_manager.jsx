/* MarkUs-specific customization of react-keyed-file-browser library.
 * Provides customized versions of the components in that library.
 */
import React from 'react'
import ClassNames from 'classnames'
import HTML5Backend, { NativeTypes } from 'react-dnd-html5-backend'
import { DragDropContext, DragSource, DropTarget } from 'react-dnd'

import { RawFileBrowser, Headers, FileRenderers, BaseFileConnectors } from 'react-keyed-file-browser'


class RawFileManager extends RawFileBrowser {
  handleActionBarAddFileClick = (event, selectedItem) => {
    event.preventDefault();
    this.props.onActionBarAddFileClick(this.folderTarget(selectedItem));
  };

  handleActionBarAddFolderClickSetSelection = (event, selectedItem) => {
    event.persist();
    const target = this.folderTarget(selectedItem);
    this.select(target, "folder");
    this.handleActionBarAddFolderClick(event)
  };

  folderTarget = (selectedItem) => {
    // treat multiple selections as not targeting a folder
    const selectionIsFolder = !!selectedItem && selectedItem.relativeKey.endsWith('/');
    if (selectedItem === null) {
      return null;
    } else if (selectionIsFolder) {
      return selectedItem.relativeKey;
    } else {
      return selectedItem.relativeKey.substring(0, selectedItem.relativeKey.lastIndexOf('/') + 1);
    }
  };

  renderActionBar(selectedItems) {
    // treat multiple selections the same as not targeting
    let selectedItem = selectedItems.length === 1 ? selectedItems[0] : null;
    const selectionIsFolder = !!selectedItem && selectedItem.relativeKey.endsWith('/');
    let filter;
    if (this.props.canFilter) {
      filter = (
        <this.props.filterRenderer
          value={this.state.nameFilter}
          updateFilter={this.updateFilter}
          {...this.props.filterRendererProps}
        />
      );
    }

    let actions = [];

    if (!this.props.readOnly && selectedItem) {
      // Something is selected. Build custom actions depending on what it is.
      if (selectedItem.action) {
        // Selected item has an active action against it. Disable all other actions.
        let actionText;
        switch (selectedItem.action) {
          case 'delete':
            actionText = 'Deleting ...';
            break

          case 'rename':
            actionText = 'Renaming ...';
            break

          default:
            actionText = 'Moving ...';
            break
        }
        actions = (
          // TODO: Enable plugging in custom spinner.
          <div className="item-actions">
            <i className="icon loading fa fa-circle-o-notch fa-spin"/> {actionText}
          </div>
        )
      }
      else {
        if (
          selectedItem &&
          !this.props.disableActions.addFolder &&
          typeof this.props.onCreateFolder === 'function' &&
          !this.state.nameFilter
        ) {
          actions.push(
            <li key="action-add-folder">
              <a
                onClick={(event) => this.handleActionBarAddFolderClickSetSelection(event, selectedItem)}
                href="#"
                role="button"
              >
                <i className="fa fa-folder-o" aria-hidden="true"/>
                &nbsp;{I18n.t('add_folder')}
              </a>
            </li>
          );
        }
        if (
          selectedItem.keyDerived &&
          !this.props.disableActions.rename && (
            (selectionIsFolder && typeof this.props.onRenameFolder === 'function') ||
            (!selectionIsFolder && typeof this.props.onRenameFile === 'function')
          )
        ) {
          actions.push(
            <li key="action-rename">
              <a
                onClick={this.handleActionBarRenameClick}
                href="#"
                role="button"
              >
                <i className="fa fa-i-cursor" aria-hidden="true"/>
                &nbsp;{I18n.t('rename')}
              </a>
            </li>
          );
        }
        if (
          selectedItem.keyDerived && (
            (!selectionIsFolder &&
              typeof this.props.onDeleteFile === 'function' &&
              !this.props.disableActions.deleteFile) ||
            (selectionIsFolder &&
              typeof this.props.onDeleteFolder === 'function' &&
              !this.props.disableActions.deleteFolder)
          )
        ) {
          actions.push(
            <li key="action-delete">
              <a
                onClick={this.handleActionBarDeleteClick}
                href="#"
                role="button"
              >
                <i className="fa fa-trash-o" aria-hidden="true"/>
                &nbsp;{I18n.t('delete')}
              </a>
            </li>
          );
        }
        // NEW
        actions.unshift(
          <li key="action-add-file>">
            <a
              onClick={(event) => this.handleActionBarAddFileClick(event, selectedItem)}
              href="#"
              role="button"
            >
              <i className="fa fa-add-file-o" aria-hidden="true"/>
              &nbsp;{I18n.t('upload_the', {item: I18n.t('file')})}
            </a>
          </li>
        );
      }
    }
    else if (!this.props.readOnly) {
      // Nothing selected.
      if (
        !this.props.disableActions.addFolder &&
        typeof this.props.onCreateFolder === 'function' &&
        !this.state.nameFilter
      ) {
        actions.push(
          <li key="action-add-folder">
            <a
              onClick={this.handleActionBarAddFolderClick}
              href="#"
              role="button"
            >
              <i className="fa fa-folder-o" aria-hidden="true"/>
              &nbsp;{I18n.t('add_folder')}
            </a>
          </li>
        )
      }
      // NEW
      actions.unshift(
        <li key="action-add-file>">
          <a
            onClick={(event) => this.handleActionBarAddFileClick(event, selectedItem)}
            href="#"
            role="button"
          >
            <i className="fa fa-add-file-o" aria-hidden="true"/>
            &nbsp;{I18n.t('upload_the', {item: I18n.t('file')})}
          </a>
        </li>
      );

      actions.push(
        <li key="action-delete" style={{color: '#8d8d8d'}}>
          <i className="fa fa-trash-o" aria-hidden="true"/>
          &nbsp;{I18n.t('delete')}
        </li>
      );
    }

    if (this.props.downloadAllURL && !this.props.disableActions.downloadAll) {
      actions.unshift(
        <li key="action-download-all">
          <a
            href={this.props.downloadAllURL}
          >
            <i className="fa fa-download-file-o" aria-hidden="true"/>
            &nbsp;{I18n.t('download_the', {item: I18n.t('all')})}
          </a>
        </li>
      );
    }

    let actionList;
    if (actions.length) {
      actionList = (<ul className="item-actions">{actions}</ul>);
    }
    else {
      actionList = (<div className="item-actions">&nbsp;</div>);
    }

    return (
      <div className="action-bar">
        {filter}
        {actionList}
      </div>
    );
  }
}


class FileManagerHeader extends Headers.TableHeader {
  render() {
    const header = (
      <tr
        className={ClassNames('folder', {
          dragover: this.props.isOver,
          selected: this.props.isSelected,
        })}
      >
        <th>{I18n.t('attributes.filename')}</th>
        <th className="modified">{I18n.t('submissions.repo_browser.submitted_at')}</th>
        <th className="modified">{I18n.t('submissions.repo_browser.revised_by')}</th>
      </tr>
    );

    if (
      typeof this.props.browserProps.createFiles === 'function' ||
      typeof this.props.browserProps.moveFile === 'function' ||
      typeof this.props.browserProps.moveFolder === 'function'
    ) {
      return header;
      // TODO: look into activating the following instead.
      // return this.props.connectDropTarget(header);
    } else {
      return header;
    }
  }
}

class FileManagerFile extends FileRenderers.RawTableFile {
  handleFileClick = (event) => {
    if (event) {
      event.preventDefault();
    }
  };

  handleItemClick = (event) => {
    // This disables the option to select multiple rows in the file manager
    // To re-enable multiple selection, remove this method entirely.
    event.stopPropagation();
    this.props.browserProps.select(this.props.fileKey, 'file')
  };

  render() {
    let icon;
    if (this.getFileType() === 'Image') {
      icon = <i className="fa fa-file-image-o" aria-hidden="true" />;
    } else if (this.getFileType() === 'PDF') {
      icon = <i className="fa fa-file-pdf-o" aria-hidden="true" />;
    } else {
      icon = <i className="fa fa-file-o" aria-hidden="true" />;
    }

    const inAction = this.props.isDragging || this.props.action;

    let name;
    if (!inAction && this.props.isDeleting) {
      name = (
        <form className="deleting" onSubmit={this.handleDeleteSubmit}>
          <a
            href={this.props.url || '#'}
            download="download"
            onClick={this.handleFileClick}
          >
            {icon}
            {this.getName()}
          </a>
          <span>
            <button type="submit">
              Confirm Deletion
            </button>
          </span>
        </form>
      );
    } else if (!inAction && this.props.isRenaming) {
      name = (
        <form className="renaming" onSubmit={this.handleRenameSubmit}>
          {icon}
          <input
            ref="newName"
            type="text"
            value={this.state.newName}
            onChange={this.handleNewNameChange}
            onBlur={this.handleCancelEdit}
            autoFocus
          />
        </form>
      );
    } else {
      name = (
        <a
          href={this.props.url || '#'}
          download={this.getName()}
        >
          {icon}
          {this.getName()}
        </a>
      );
    }

    let draggable = (
      <div>
        {name}
      </div>
    );
    if (typeof this.props.browserProps.moveFile === 'function') {
      draggable = this.props.connectDragPreview(draggable)
    }

    let row = (
      <tr
        className={ClassNames('file', {
          pending: (this.props.action),
          dragging: (this.props.isDragging),
          dragover: (this.props.isOver),
          selected: (this.props.isSelected),
        })}
        onClick={this.handleItemClick}
        onDoubleClick={this.handleItemDoubleClick}
      >
        <td className="name">
          <div style={{paddingLeft: (this.props.depth * 16) + 'px'}}>
            {draggable}
          </div>
        </td>
        <td className="modified">
          {typeof this.props.submitted_date === 'undefined' ? '-' : this.props.submitted_date}
        </td>
        <td className="modified">
          {this.props.revision_by}
        </td>
      </tr>
    );

    return this.connectDND(row)
  }
}

FileManagerFile = (
  DragSource('file', BaseFileConnectors.dragSource, BaseFileConnectors.dragCollect)(
    DropTarget(['file', 'folder', NativeTypes.FILE],
               BaseFileConnectors.targetSource,
               BaseFileConnectors.targetCollect,
    )(FileManagerFile))
);


let FileManager = DragDropContext(HTML5Backend)(RawFileManager);

FileManager.defaultProps = {
  headerRenderer: FileManagerHeader,
  fileRenderer: FileManagerFile,
  icons: {
    File: <i className="fa fa-file-o" aria-hidden="true" />,
    Image: <i className="fa fa-file-image-o" aria-hidden="true" />,
    PDF: <i className="fa fa-file-pdf-o" aria-hidden="true" />,
    Rename: <i className="fa fa-i-cursor" aria-hidden="true" />,
    Folder: <i className="fa fa-folder-o" aria-hidden="true" />,
    FolderOpen: <i className="fa fa-folder-open-o" aria-hidden="true" />,
    Delete: <i className="fa fa-trash-o" aria-hidden="true" />,
    Loading: <i className="fa fa-circle-o-notch fa-spin" aria-hidden="true" />,
  },
  disableActions: {}
};


export default FileManager;
export {
  FileManagerHeader,
  FileManagerFile
}
