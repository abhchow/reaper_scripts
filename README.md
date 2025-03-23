This repository contains scripts to extend functionality in REAPER.
They are written in Lua using the built-in [ReaScript API](https://www.reaper.fm/sdk/reascript/reascript.php), with the added functionality of the [Ultraschall API Library](https://mespotin.uber.space/Ultraschall/US_Api_Introduction_and_Concepts.html)

Currently I only have one script which is designed to make custom configurations for choir or a cappella learning tracks. It renders the following configurations of the tracks in a Reaper project:
- Each part panned hard left, with the other parts panned hard right
- A full mix of all parts, with panning across the stereo spectrum so that each part has its own space
- A mix with each part missing, so that you can test yourself to see how well you hold your part without the support of the other parts (these use the same panning arrangement as the full mix)
- Rhythm only track (Bass and Vocal Percussion) for arrangements that have a VP part
- Rhythm panned part, like the other panned tracks, except that both Bass and VP are panned hard left

I have further improvements to this script planned, but I may or may not get to them. Those include:
- A GUI for ease of use
- Options to choose panning hard left or hard right
- Options to select a custom panning arrangement for full mix and part missing tracks
- Options to select custom combinations of different parts present, not just Bass and VP
