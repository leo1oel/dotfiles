/**
 * Joseph TV Focus Layout for Amethyst
 * My custom layout for my 48" LG OLED C1 TV
 *
 * Main pane is the bottom center of the screen at the default of 60% width and 75% height (can be adjusted with custom keys)
 * Secondary panes are distributed on the top (Maximum of 3 panes) and the Side Panes (One pane each side)
 * The overflow panes are placed behind the main pane.
 *
 * |------------------------------------------------------------------------------------------|
 * |                             |                              |                             |
 * |                             |                              |                             |
 * |         Top Pane 1          |          Top Pane 2          |         Top Pane 3          |
 * |                             |                              |                             |
 * |                             |                              |                             |
 * |------------------------------------------------------------------------------------------|
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |      Left       |                                                     |       Right      |
 * |      Side       |                       Main Pane                     |       Side       |
 * |      Pane       |                                                     |       Pane       |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |                 |                                                     |                  |
 * |------------------------------------------------------------------------------------------|
 */

function layout() {
    return {
        name: "Joseph TV Focus",
        initialState: {
            mainPaneHeightRatio: 0.70,
            mainPaneWidthRatio: 0.60
        },
        commands: {
            command3: {  // shrink Main Width
                description: "Decrease main pane width", // 0.38 to 0.82 (-0.02)
                updateState: (state) => {
                    return { ...state, mainPaneWidthRatio: state.mainPaneWidthRatio < 0.38 ? 0.38 : state.mainPaneWidthRatio - 0.02 };
                }
            },
            command4: {  // expand Main Width
                description: "Increase main pane width", // 0.38 to 0.82 (+0.02)
                updateState: (state) => {
                    return { ...state, mainPaneWidthRatio: state.mainPaneWidthRatio > 0.82 ? 0.82 : state.mainPaneWidthRatio + 0.02 };
                }
            },
            command1: {  // shrink Main Height
                description: "Decrease main pane height", // 0.2 to 0.9 (-0.02)
                updateState: (state) => {
                    return { ...state, mainPaneHeightRatio: state.mainPaneHeightRatio < 0.2 ? 0.2 : state.mainPaneHeightRatio - 0.02 };
                }
            },
            command2: {  // expand Main Height
                description: "Increase main pane height",  // 0.2 to 0.9 (+0.02)
                updateState: (state) => {
                    return { ...state, mainPaneHeightRatio: state.mainPaneHeightRatio > 0.9 ? 0.9 : state.mainPaneHeightRatio + 0.02 };
                }
            }
        },
        getFrameAssignments: (windows, screenFrame, state) => {

            // 3 top panes, 2 side panes, the rest are Main Panes
            const mainPaneWindowWidth = Math.round(screenFrame.width * state.mainPaneWidthRatio);
            const mainPaneWindowHeight = Math.round(screenFrame.height * state.mainPaneHeightRatio);

            const topPaneWindowWidth = Math.round(screenFrame.width / 3);
            const topPaneWindowHeight = Math.round(screenFrame.height - mainPaneWindowHeight);

            const sidePaneWindowWidth = Math.round((screenFrame.width - mainPaneWindowWidth) / 2);
            const sidePaneWindowHeight = mainPaneWindowHeight;

            return windows.reduce((frames, window, index) => {
                let frame;

                /*****
                 * Process Main Pane and Overflow Panes
                 * bottom center of the screen at 60% width and 75% height
                 */
                if (index == 0 || index > 5) {
                    frame = {
                        x: screenFrame.x + Math.round((screenFrame.width - mainPaneWindowWidth) / 2),
                        y: screenFrame.y + screenFrame.height - mainPaneWindowHeight,
                        width: mainPaneWindowWidth,
                        height: mainPaneWindowHeight
                    };

                /*****
                 * Process Top Panes
                 * Maximum of 3 panes
                 */
                } else if (index < 4) {
                    frame = {
                        x: screenFrame.x + (topPaneWindowWidth * (index - 1)),
                        y: screenFrame.y,
                        width: topPaneWindowWidth,
                        height: topPaneWindowHeight
                    };

                /*****
                 * Process Left Side Pane
                 */
                } else if (index == 4) {
                    frame = {
                        x: screenFrame.x,
                        y: screenFrame.y + topPaneWindowHeight,
                        width: sidePaneWindowWidth,
                        height: sidePaneWindowHeight
                    };

                /*****
                 * Process Right Side Pane
                 */
                } else if (index == 5) {
                    frame = {
                        x: screenFrame.x + screenFrame.width - sidePaneWindowWidth,
                        y: screenFrame.y + topPaneWindowHeight,
                        width: sidePaneWindowWidth,
                        height: sidePaneWindowHeight
                    };
                }
                return { ...frames, [window.id]: frame };
            }, {});
        }
    };
}
