# socket.io (websockets) feature

socketio = require 'socket.io'
module.exports = -> @async ->
  express = @require 'express'
  express.once 'listening', (server) =>
    console.info "[websocket] binding to server"
    io = socketio server
    io.on 'connection', (socket) =>
      console.log '[websocket] User connected. socket id %s', socket.id
      keys = @get('/server/router/name')
      socket.on 'join', (rooms...) ->
        rooms = [].concat rooms...
        console.log '[socket:%s] Joining %s', socket.id, rooms
        socket.join room for room in rooms when room in ids
      socket.on 'leave', (rooms...) ->
        rooms = [].concat rooms...
        console.log '[socket:%s] Leaving %s', socket.id, rooms
        socket.leave room for room in rooms
      socket.on 'knock', ->
        console.log '[socket:%s] Knocking for rooms', socket.id
        keys = @get('/server/router/name')
        socket.emit 'rooms', keys
      socket.emit 'rooms', keys

      # TODO: this should be bound to each room?
      socket.on 'fetch', ->
        console.log "[websocket] User requested fetch"
        console.log arguments
        console.log this

    # setup initial update sync notifications
    @get('/server/router/name').forEach (router) =>
      @access(router).on 'update', (prop) ->
        io.to(@name).emit 'sync', data: prop.path

    # attach update listener when new router is added
    @on 'create', '/server/router', (prop) =>
      @access(prop.name).on 'update', (prop) ->
        io.to(@name).emit 'sync', data: prop.path

    # disconnect room when router is removed
    @on 'delete', '/server/router', (prop) ->
      io.to(prop.name).emit 'disconnect'

    next io
