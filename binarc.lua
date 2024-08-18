-- BINary ARChive
-- for ComputerCraft
-- bundles multiple files in a single binary file

local binser = require 'lib.binser'

function table.slice(tbl, first, last, step)
    local sliced = {}
    
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end
    
    return sliced
end

local function tablePrint(t)
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(k, '{')
            tablePrint(v)
            print('}')
        else
            print(k, v)
        end
    end
end

local function usage()
    print('Usage:')
    print('  binarc <command> <archive> [optional parameters...]')
    print('Commands:')
    print('  add:     add files, folders, or a group of files to the specified archive')
    print('  remove:  remove files or folders from the specified archive')
    print('  extract: write all of the files and folders in a specified archive to local storage')
    print('  list:    list every file on the archive')
    return 127
end

local function mountArchive(path)
    local file = fs.open(path, 'r')
    local results, len = binser.deserialize(file.readAll())
    file.close()
    return results[1]
end

local function writeArchive(path, archive)
    local file = fs.open(path, 'w')
    local serializedArchive = binser.serialize(archive)
    file.write(serializedArchive)
    file.close()
    return fs.getSize(path)
end

local args = {...}

if #args < 2 then
    return usage()
end

local command = args[1]
local archivePath = shell.resolve(args[2])

if command == 'add' then
    if #args < 3 then
        print('Must provide at least one file, folder, or group of files to add to the archive.')
        return 127
    end

    local archive = {}
    if fs.exists(archivePath) then
        archive = mountArchive(archivePath)
    end

    local files = {}
    for i = 3, #args do
        for j, w in ipairs(fs.find(shell.resolve(args[i]))) do
            table.insert(files, w)
        end
    end

    local function addList(archive, files)
        for i, v in ipairs(files) do
            print(v .. ' (' .. fs.getSize(v) .. ' B)')
            if fs.exists(v) then
                if not fs.isDir(v) then
                    if archive[fs.getName(v)] ~= nil then
                        print('File already in archive, overwriting...')
                    end
                    local file = fs.open(v, 'r')
                    archive[fs.getName(v)] = file.readAll()
                    file.close()

                    term.setTextColor(colors.green)
                    print('File written!')
                    term.setTextColor(colors.white)
                else
                    if archive[fs.getName(v)] == nil then
                        archive[fs.getName(v)] = {}
                    end
                    local subFolderFiles = {}
                    for j, w in ipairs(fs.list(v)) do
                        table.insert(subFolderFiles, fs.combine(v, w))
                    end
                    addList(archive[fs.getName(v)], subFolderFiles)
                end
            end
        end
    end

    addList(archive, files)

    local archiveSize = writeArchive(archivePath, archive)
    print('Total archive size: ' .. archiveSize .. ' B')
elseif command == 'remove' then

elseif command == 'extract' then
    if #args > 3 then
        print('Expected either no argument at all, or a directory path to extract to')
        return 127
    end

    local extractionDirectory = shell.resolve(args[3] or '')

    if not fs.exists(archivePath) then
        print('Archive not found.')
        return 127
    end

    local archive = mountArchive(archivePath)
    local overwriteExistingFiles = 0 -- -1 = never, 0 = ask, 1 = always

    local function extractArchive(archive, path)
        local fileWriteCount = 0
        for k, v in pairs(archive) do
            local fPath = fs.combine(path, k)
            local writeFile = (overwriteExistingFiles == 1) or (not fs.exists(fPath)) and (not fs.isReadOnly(fPath))

            if type(v) == 'table' then
                fileWriteCount = fileWriteCount + extractArchive(v, fPath)
            else
                if fs.exists(fPath) and not fs.isReadOnly(fPath) and overwriteExistingFiles == 0 then
                    term.setTextColor(colors.cyan)
                    print('The file "' .. fPath .. '" already exists. Overwrite?')
                    term.setTextColor(colors.white)
                    write('(Y)es, (Y*)es to all, (N)o, (N*)o to all: ')
                    local command = read():lower()
                    if command == 'y' or command == 'y*' then
                        writeFile = true
                    end
                    if command == 'y*' then
                        overwriteExistingFiles = 1
                    end
                    if commmand == 'n' or command == 'n*' then
                        writeFile = false
                    end
                    if commmand == 'n*' then
                        overwriteExistingFiles = -1
                    end
                end
                if writeFile and not fs.isReadOnly(fPath) then
                    local file = fs.open(fPath, 'w')
                    file.write(v)
                    file.close()
                    fileWriteCount = fileWriteCount + 1
                    print('Extracted file ' .. fPath)
                end
            end
        end
        return fileWriteCount
    end

    local fileCount = extractArchive(archive, extractionDirectory)
    term.setTextColor(colors.green)
    print('Extracted ' .. fileCount .. ' file(s)!')
    term.setTextColor(colors.white)
elseif command == 'list' then
    local archive = mountArchive(archivePath)

    local function archivePrint(t, pad)
        local pad = pad or 0
        local padStr = string.rep(" ", pad)
        for k, v in pairs(t) do
            if type(v) == 'table' then
                print(padStr .. k .. '/')
                archivePrint(v, pad+2)
            else
                print(padStr .. k)
            end
        end
    end

    archivePrint(archive)
else
    return usage()
end