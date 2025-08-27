/**
 * Joseph TV IDE Layout for Amethyst
 * My custom layout for my 48" LG OLED C1 TV
 *
 * Main pane is the bottom 60% of the screen
 * Secondary panes are the top 40% of the screen (Maximum of 3 panes)
 * The overflow panes are placed in the bottom centre of the screen.
 */

function layout() {
    return {
        name: "Joseph TV IDE",
        initialState: {
            mainPaneCount: 0,
            mainPaneRatio: 0.6,
            firstPaneRatio: 0.9
        },
        commands: {
            command3: {  // decreaseMain
                description: "Decrease main pane ratio", // 0.38 to 0.82 (-0.02)
                updateState: (state) => {
                    return { ...state, mainPaneRatio: state.mainPaneRatio < 0.38 ? 0.38 : state.mainPaneRatio - 0.02 };
                }
            },
            command4: {  // increaseMain
                description: "Increase main pane ratio", // 0.38 to 0.82 (+0.02)
                updateState: (state) => {
                    return { ...state, mainPaneRatio: state.mainPaneRatio > 0.82 ? 0.82 : state.mainPaneRatio + 0.02 };
                }
            },
            command1: {  // shrinkMain
                description: "Decrease first pane ratio", // 0.2 to 0.9 (-0.02)
                updateState: (state) => {
                    let mainPaneCount = state.mainPaneCount;
                    if (mainPaneCount == 0) {
                        return { ...state, mainPaneCount: 1, firstPaneRatio: 0.9 };
                    } else if (state.firstPaneRatio <= 0.76) {
                        mainPaneCount = 3;
                    } else {
                        mainPaneCount = 1;
                    }
                    return { ...state, firstPaneRatio: state.firstPaneRatio <= 0.2 ? 0.2 : state.firstPaneRatio -= 0.02, mainPaneCount: mainPaneCount };
                }
            },
            command2: {  // expandMain
                description: "Increase first pane ratio",  // 0.2 to 0.9 (+0.02)
                updateState: (state) => {
                    let mainPaneCount = state.mainPaneCount;
                    if (state.firstPaneRatio >= 0.9) {
                        mainPaneCount = 0;
                    } else if (state.firstPaneRatio > 0.76) {
                        mainPaneCount = 1;
                    } else {
                        mainPaneCount = 3;
                    }
                    return { ...state, firstPaneRatio: state.firstPaneRatio >= 0.9 ? 0.9 : state.firstPaneRatio += 0.02, mainPaneCount: mainPaneCount };
                }
            }
        },
        getFrameAssignments: (windows, screenFrame, state) => {
            const wideMainWindow = state.mainPaneCount == 0;
            const mainPaneCount = Math.min(state.mainPaneCount || 1, windows.length);
            const secondaryPaneCount = Math.min(4, windows.length - mainPaneCount);
            const hasSecondaryPane = secondaryPaneCount > 0;

            const firstPaneWindowWidth = Math.round(screenFrame.width * state.firstPaneRatio);
            const mainPaneWindowHeight = Math.round(screenFrame.height * state.mainPaneRatio);
            const secondaryPaneWindowHeight = Math.round(screenFrame.height * (1 - state.mainPaneRatio));

            return windows.reduce((frames, window, index) => {
                const isMain = index < mainPaneCount;
                let frame;

                // Process Main Pane
                if (isMain) {
                    const mainPaneWindowWidth = Math.round(screenFrame.width / mainPaneCount);

                    // Single Main take full width
                    if (mainPaneCount == 1) {
                        const s_block = Math.round((screenFrame.width - firstPaneWindowWidth) / 2);
                        if (wideMainWindow) {
                            frame = {
                                x: screenFrame.x,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: screenFrame.width,
                                height: mainPaneWindowHeight
                            };
                        } else {
                            frame = {
                                x: screenFrame.x + s_block,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: firstPaneWindowWidth,
                                height: mainPaneWindowHeight
                            };
                        }

                    // 2nd Main take the 1st 1/3 (Wide Mode) or 1/2
                    } else if (mainPaneCount == 2) {
                        const s_block = screenFrame.width - firstPaneWindowWidth;
                        if (index == 0) {
                            frame = {
                                x: screenFrame.x + s_block,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: firstPaneWindowWidth,
                                height: mainPaneWindowHeight
                            };
                        } else {
                            frame = {
                                x: screenFrame.x,
                                y: screenFramey + secondaryPaneWindowHeight,
                                width: s_block,
                                height: mainPaneWindowHeight
                            };
                        }

                    // 3 or more Main Panel: 2nd Main take the 1st 1/4, 3rd+ take last 1/4
                    } else {
                        const s_block = Math.round((screenFrame.width - firstPaneWindowWidth) / 2);
                        if (index == 0) {
                            frame = {
                                x: screenFrame.x + s_block,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: firstPaneWindowWidth,
                                height: mainPaneWindowHeight
                            };
                        } else if (index == 1) {
                            frame = {
                                x: screenFrame.x,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: s_block,
                                height: mainPaneWindowHeight
                            };
                        } else {
                            frame = {
                                x: screenFrame.x + s_block + firstPaneWindowWidth,
                                y: screenFrame.y + secondaryPaneWindowHeight,
                                width: s_block,
                                height: mainPaneWindowHeight
                            };
                        }
                    }

                /*****
                 * Process non-Main Panes
                 */
                } else if (hasSecondaryPane) {
                    const secondaryPaneIndex = index - mainPaneCount
                    /*****
                     Process Second Pane
                     1st 3 panes on top
                    */
                    if (secondaryPaneIndex < 3) {
                        const secondaryPaneWindowWidth = screenFrame.width / 3;
                        frame = {
                            x: screenFrame.x + (secondaryPaneWindowWidth * Math.min(4, secondaryPaneIndex)),
                            y: screenFrame.y,
                            width: secondaryPaneWindowWidth,
                            height: secondaryPaneWindowHeight
                        }

                    /*****
                     * Overflow panes are placed in the bottom centre of the screen.
                     */
                    } else {
                        const u_width = screenFrame.width / 6
                        const u_height = screenFrame.height / 3
                        frame = {

                            x: screenFrame.x + u_width,
                            y: screenFrame.y + u_height,
                            width: u_width * 4,
                            height: u_height * 2
                        }
                    }
                }
                return { ...frames, [window.id]: frame };
            }, {});
        }
    };
}
