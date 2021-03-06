#
#class based on the dpm wiki example
#
class dpm::disknode (
  $configure_vos =  $dpm::params::configure_vos,
  $configure_gridmap =  $dpm::params::configure_gridmap,

  #cluster options
  $headnode_fqdn =  $dpm::params::headnode_fqdn,
  $disk_nodes =  $dpm::params::disk_nodes,
  $localdomain =  $dpm::params::localdomain,
  $webdav_enabled = $dpm::params::webdav_enabled,

  #dpmmgr user options
  $dpmmgr_uid =  $dpm::params::dpmmgr_uid,

  #Auth options
  $token_password =  $dpm::params::token_password,
  $xrootd_sharedkey =  $dpm::params::xrootd_sharedkey,
  $xrootd_use_voms =  $dpm::params::xrootd_use_voms,
  
  #VOs parameters
  $volist =  $dpm::params::volist,
  $groupmap =  $dpm::params::groupmap,
  
  #Debug Flag
  $debug = $dpm::params::debug,
  
  )inherits dpm::params {

    Class[Lcgdm::Base::Install] -> Class[Lcgdm::Rfio::Install]
    if($webdav_enabled){
      Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Dav::Service]
    }
    Class[Dmlite::Plugins::Adapter::Install] ~> Class[Dmlite::Gridftp]

    # lcgdm configuration.
    #
    class{"lcgdm::base":
      uid     => $dpmmgr_uid,
    }
   
    
    class{"lcgdm::ns::client":
      flavor  => "dpns",
      dpmhost => "${headnode_fqdn}"
    }

    #
    # RFIO configuration.
    #
    class{"lcgdm::rfio":
      dpmhost => $headnode_fqdn,
    }
    
    #
    # Entries in the shift.conf file, you can add in 'host' below the list of
    # machines that the DPM should trust (if any).
    #
    lcgdm::shift::trust_value{
      "DPM TRUST":
        component => "DPM",
        host      => "${headnode_fqdn} ${disk_nodes}";
      "DPNS TRUST":
        component => "DPNS",
        host      => "${headnode_fqdn} ${disk_nodes}";
      "RFIO TRUST":
        component => "RFIOD",
        host      => "${headnode_fqdn} ${disk_nodes}",
        all       => true
    }
    lcgdm::shift::protocol{"PROTOCOLS":
      component => "DPM",
      proto     => "rfio gsiftp http https xroot"
    }

    #if($configure_vos){
    #  class{ $volist.map |$vo| {"voms::$vo"}:}
    #  #Create the users: no pool accounts just one user per group
    #  ensure_resource('user', values($groupmap), {ensure => present})
    #}


    if($configure_gridmap){
      #setup the gridmap file
      lcgdm::mkgridmap::file {"lcgdm-mkgridmap":
        configfile   => "/etc/lcgdm-mkgridmap.conf",
        localmapfile => "/etc/lcgdm-mapfile-local",
        logfile      => "/var/log/lcgdm-mkgridmap.log",
        groupmap     => $groupmap,
        localmap     => {"nobody" => "nogroup"}
      }
    }
    
    
    #
    # dmlite plugin configuration.
    class{"dmlite::disk":
      token_password => "${token_password}",
      dpmhost        => "${headnode_fqdn}",
      nshost         => "${headnode_fqdn}",
    }
    
    #
    # dmlite frontend configuration.
    #
    if($webdav_enabled){
      class{"dmlite::dav":}
    }
    
    class{"dmlite::gridftp":
      dpmhost => "${headnode_fqdn}"
    }

    # The XrootD configuration is a bit more complicated and
    # the full config (incl. federations) will be explained here:
    # https://svnweb.cern.ch/trac/lcgdm/wiki/Dpm/Xroot/PuppetSetup
    
    #
    # The simplest xrootd configuration.
    #
    class{"xrootd::config":
      xrootd_user  => $dpmmgr_user,
      xrootd_group => $dpmmgr_user
    }
    
    class{"dmlite::xrootd":
      nodetype              => [ 'disk' ],
      domain                => "${localdomain}",
      dpm_xrootd_debug      => $debug,
      dpm_xrootd_sharedkey  => "${xrootd_sharedkey}",
    }
    
  }
                                                                                                    
