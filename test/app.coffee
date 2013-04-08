async = require 'async'
path = require 'path'
fs = require 'fs'
request = require 'request'
db = require "../src/db"
app = require "../src/app"
assert = require('chai').assert

db.test = true

PORT = 3300

GET_TEST_FILE = ( name ) ->
    path.join path.dirname(__filename) , 'app' , name

GET = ( path , cb ) ->
    request.get "http://127.0.0.1:#{PORT}#{path}" , ( err , res , body ) ->
        cb JSON.parse(body)

PUT = ( path , file , cb ) ->
    fs.createReadStream( file ).pipe( 
        request.put "http://127.0.0.1:#{PORT}#{path}", ( err , res , body ) ->
            cb JSON.parse(body)
    )

app.startApp(PORT,{
        test : true
    })

describe 'app' , ->

    before ( done ) ->
        db.clearDB done

    it '#get /:pkgname should be missing.' , ( done ) ->

        GET '/datepicker' , ( json ) ->
            assert.equal json.ret , false
            done()

    after ( done ) ->
        db.clearDB done


describe 'app' , ->

    before ( done ) ->
        db.clearDB done

    it '#put /:pkgname' , ( done ) ->

        PUT '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , ( body ) ->
            assert.ok body.ret
            db.find 'datepicker' , (err, json) ->
                done()

    it '#put /:pkgname second' , ( done ) ->

        PUT '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , ( body ) ->
            assert.ok body.ret
            db.find 'datepicker' , (err, json) ->
                done()

    after ( done ) ->
        db.clearDB done


describe 'app' , ->

    before ( done ) ->
        a = ( ok ) ->
            db.clearDB ok
        b = ( ok ) ->
            PUT '/datepicker' , GET_TEST_FILE('datepicker-0.0.1.tgz') , () ->
                ok()
        c = ( ok ) ->
            PUT '/datepicker' , GET_TEST_FILE('datepicker-0.0.2.tgz') , () ->
                ok()
        async.series [a,b,c] , () ->
            done()


    it '#get /:pkgname/latest' , ( done ) ->

        GET '/datepicker/latest' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data.version , '0.0.2'
            done()


    it '#get /:pkgname/0.0.1' , ( done ) ->

        GET '/datepicker/0.0.1' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data.version , '0.0.1'
            done()


    it '#get /:pkgname' , ( done ) ->

        GET '/datepicker' , ( body ) ->
            assert.equal body.ret , true
            assert.equal body.data['dist-tags']['latest'] , '0.0.2'
            done()


    after ( done ) ->
        db.clearDB done


