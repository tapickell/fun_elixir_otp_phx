import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

function newChannel(player, screen_name) {
  return socket.channel("game:" + player, {screen_name: screen_name});
}

function joinChannel(channel) {
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp); })
    .receive("error", resp => { console.log("Unable to join", resp); });
}

function channelPresence(channel) {
  channel.on("subscribers", resp => {
    console.log("These players have joined: ", resp);
  });
}

function listSubs(channel) {
  channel.push("show_subscribers");
}

let tommy_gc = newChannel("Tommy", "Tommy");
channelPresence(tommy_gc);

joinChannel(tommy_gc);
listSubs(tommy_gc);

export {
  newChannel,
  joinChannel,
  channelPresence,
  listSubs
}
