#!/usr/bin/osascript -l JavaScript
"use strict";

(() => {
  const finderApp = Application("Finder");
  if (finderApp.trash().items().length === 0) {
    return;
  }

  const systemEventsApp = Application("System Events");
  const frontmostProcess = systemEventsApp.processes.whose({ frontmost: true })[0];
  const frontmostApp = Application(frontmostProcess.displayedName());

  finderApp.includeStandardAdditions = true;
  finderApp.activate();

  let result;
  try {
    result = finderApp.displayAlert(
      "Are you sure you want to permanently erase the items in the Trash?",
      {
        message: "You can't undo this action.",
        as: "critical",
        buttons: ["Cancel", "Empty Trash"],
        defaultButton: "Empty Trash",
        cancelButton: "Cancel",
      }
    );
  } catch (e) {
    result = { buttonReturned: "Cancel" };
  }

  if (result.buttonReturned === "Empty Trash") {
    try {
      finderApp.empty();
    } catch (e) {
    }
  }

  frontmostApp.activate();
})();
