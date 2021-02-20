# �G���[�������������~����
$ErrorActionPreference = 'Stop'

$TargetDirectory = "C:\temp\SS�O���[�v����"

function getdatetime_from_filename { # VRChat_1920x1080_2020-06-03_23-41-39.341.jpg
  Param($file)
  $ret = Get-Date "9999/12/31 23:59:59"
  if ($file.Name.StartsWith("VRChat_")) {
    $tmp = $file.Name.Substring($file.Name.IndexOf('x')+1,$file.Name.Length - ($file.Name.IndexOf('x')+1))
    $y = $tmp.Substring($tmp.IndexOf('_')+1,4)
    $m = $tmp.Substring($tmp.IndexOf('-')+1,2)
    $d = $tmp.Substring($tmp.IndexOf('-')+4,2)
    $tmp = $tmp.Substring($tmp.IndexOf('_')+12,$tmp.Length - ($tmp.IndexOf('_')+12))
    $hur = $tmp.Substring(0,2)
    $min = $tmp.Substring(3,2)
    $sec = $tmp.Substring(6,2)
    $filedatestring = $y + "/" + $m + "/" + $d + " " + $hur + ":" + $min + ":" + $sec
    $ret = get-date $filedatestring
  }
  return $ret
}

function getdatetime {
  Param($file)
  $ret = getdatetime_from_filename($file)
  if ($ret -gt $file.CreationTime)   { $ret = $file.CreationTime   }
  if ($ret -gt $file.LastWriteTime)  { $ret = $file.LastWriteTime  }
  if ($ret -gt $file.LastAccessTime) { $ret = $file.LastAccessTime }
  return $ret
}

class MyFile {
  # �v���p�e�B�ϐ�
  [Object] $file
  [Object] $datetime
  [Object] $distance

  # �R���X�g���N�^�[
  MyFile($in_file) {
    $this.file = $in_file
    $this.datetime = getdatetime($in_file)
    $this.distance = -1
  }

  # getter
  [Object] file() {
    return $this.file
  }
  [Object] datetime() {
    return $this.datetime
  }
  [Object] distance() {
    return $this.distance
  }

  #setter
  set_distance([Object] $in_distance) {
    $this.distance = $in_distance
  }
}

class MyFiles {
  $file_arr = @()

  # MyFile��ǉ�
  AddFile([MyFile] $in_myfile) {
    $this._AddFile($in_myfile)
    # $this._check()
  }

  _AddFile([MyFile] $in_myfile) {
    if ($this.file_arr.Length -eq 0) { # -eq ==
      # �z�񂪋�Ȃ̂ŁA���̂܂ܔz��ɗv�f��ǉ�
      $this.file_arr += $in_myfile
      return
    }
    # �z��́A�}�����ׂ��ʒu������
    if ($this.file_arr[$this.file_arr.Length - 1].datetime -le $in_myfile.datetime) { # -le <=
      # �z��̍Ō�ɒǉ�
      $in_myfile.distance = $in_myfile.datetime - $this.file_arr[$this.file_arr.Length-1].datetime
      $this.file_arr += $in_myfile
      return
    }
    for ( $i=($this.file_arr.Length-2) ; $i -ge 0; $i-- ) { # -ge >=
      if ($this.file_arr[$i].datetime -lt $in_myfile.datetime) { # lt <
        # �z����A�}�����ׂ��ʒu�́u�O�v�Ɓu���v�ɕ�����
        $zenhan = $this.file_arr[0..$i]
        $kouhan = $this.file_arr[($i+1)..($this.file_arr.Length-1)]
        # distance���v�Z
        $in_myfile.distance = $in_myfile.datetime - $zenhan[$zenhan.Length-1].datetime
        $kouhan[0].distance = $kouhan[0].datetime - $in_myfile.datetime
        # �O���A$in_myfile�A�㔼���q����
        $this.file_arr = @() + $zenhan + $in_myfile + $kouhan
        return
      }
    }
    # �z��̐擪�ɒǉ�
    $this.file_arr[0].distance = $this.file_arr[0].datetime - $in_myfile.datetime
    $this.file_arr = @() + $in_myfile + $this.file_arr
  }

  _check() {
    if ($this.file_arr.Length -le 1) {
      return
    }
    for ($i=1 ; $i -lt $this.file_arr.Length; $i++){
      if ($this.file_arr[$i-1].datetime -gt $this.file_arr[$i].datetime) { # -gt >
        # �����i�召�j����������
        return
      }
      if ($this.file_arr[$i].distance -lt 0) { # -lt <
        # �P�O�̃t�@�C���Ƃ̎��ԋ�������������
        return
      }
    }
  }

  # �ǉ����ꂽMyFile�̔z���Ԃ�
  [array] get_files() {
    return $this.file_arr
  }

  [array] get_groups() {
    $ret = $null
    $diff = (get-date "2000/01/01 06:00:00") - (get-date "2000/01/01 00:00:00")
    for ($i=0 ; $i -lt $this.file_arr.Length; $i++){
      if (($this.file_arr[$i].distance -lt 0) -or ($this.file_arr[$i].distance -gt $diff)) {
        $ret += ,@()
      }
      $ret[$ret.Length-1] += $this.file_arr[$i]
    }
    return $ret
  }
}

##### start here #####

$files = New-Object MyFiles
Set-Location $TargetDirectory
Get-ChildItem $TargetDirectory | Where-Object { ! $_.PSIsContainer } | ForEach-Object {
  $tmp_file = New-Object MyFile($_)
  $files.AddFile($tmp_file)
}

$files.get_groups() | ForEach-Object {
  $folder_name = $_[0].datetime.ToString("yyyyMMdd-HHmmss") + "_" + $_[-1].datetime.ToString("yyyyMMdd-HHmmss")
  Set-Location $TargetDirectory
  New-Item -ItemType Directory -Force $folder_name
  $_ | ForEach-Object {
    Move-Item $_.file $folder_name
  }
}
