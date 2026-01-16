#!/usr/bin/env python3
"""
Script to add new offline mode files to Xcode project
"""
import re
import uuid

def generate_uuid():
    """Generate a UUID in Xcode format (24 uppercase hex chars)"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(project_path, files_to_add, group_name_to_uuid):
    """
    Add files to Xcode project.pbxproj file

    Args:
        project_path: Path to project.pbxproj
        files_to_add: List of (filename, filepath, group_uuid) tuples
        group_name_to_uuid: Dict mapping group names to their UUIDs
    """
    with open(project_path, 'r') as f:
        content = f.read()

    # Find the main group UUID (PetSafety target sources)
    main_sources_match = re.search(r'/\* PetSafety \*/.*?isa = PBXGroup;.*?children = \((.*?)\);', content, re.DOTALL)

    if not main_sources_match:
        print("ERROR: Could not find main PetSafety group")
        return False

    # Generate file references
    file_references = []
    build_file_entries = []
    sources_build_phase_entries = []

    for filename, filepath, group_uuid in files_to_add:
        file_ref_uuid = generate_uuid()
        build_file_uuid = generate_uuid()

        # Create PBXFileReference entry
        file_ref = f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
        file_references.append((file_ref_uuid, filename, file_ref))

        # Create PBXBuildFile entry
        build_file = f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};\n"
        build_file_entries.append((build_file_uuid, filename, build_file))

        # Add to group children
        sources_build_phase_entries.append((build_file_uuid, filename))

        # Add file reference to appropriate group
        group_pattern = rf'({group_uuid} /\* .* \*/ = {{.*?children = \()(.*?)(\);.*?isa = PBXGroup;)'
        group_match = re.search(group_pattern, content, re.DOTALL)

        if group_match:
            existing_children = group_match.group(2)
            new_child = f"\n\t\t\t\t{file_ref_uuid} /* {filename} */,"
            updated_children = existing_children + new_child
            content = content[:group_match.start(2)] + updated_children + content[group_match.end(2):]
            print(f"✓ Added {filename} to group")
        else:
            print(f"✗ Could not find group {group_uuid} for {filename}")

    # Add file references to PBXFileReference section
    pbx_file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/', content)
    if pbx_file_ref_section:
        insert_pos = pbx_file_ref_section.end()
        for uuid, name, ref in file_references:
            content = content[:insert_pos] + '\n' + ref + content[insert_pos:]
            insert_pos += len('\n' + ref)
        print(f"✓ Added {len(file_references)} file references")

    # Add build file entries to PBXBuildFile section
    pbx_build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/', content)
    if pbx_build_file_section:
        insert_pos = pbx_build_file_section.end()
        for uuid, name, build_file in build_file_entries:
            content = content[:insert_pos] + '\n' + build_file + content[insert_pos:]
            insert_pos += len('\n' + build_file)
        print(f"✓ Added {len(build_file_entries)} build file entries")

    # Add to PBXSourcesBuildPhase (compile sources)
    sources_phase_pattern = r'(/\* Sources \*/ = {.*?files = \()(.*?)(\);.*?isa = PBXSourcesBuildPhase;)'
    sources_match = re.search(sources_phase_pattern, content, re.DOTALL)

    if sources_match:
        existing_files = sources_match.group(2)
        new_files_str = ""
        for uuid, name in sources_build_phase_entries:
            new_files_str += f"\n\t\t\t\t{uuid} /* {name} in Sources */,"
        updated_files = existing_files + new_files_str
        content = content[:sources_match.start(2)] + updated_files + content[sources_match.end(2):]
        print(f"✓ Added {len(sources_build_phase_entries)} files to Sources build phase")
    else:
        print("✗ Could not find Sources build phase")

    # Write updated content
    with open(project_path, 'w') as f:
        f.write(content)

    return True

def find_group_uuid(content, group_name):
    """Find UUID of a group by name"""
    pattern = rf'([A-F0-9]{{24}}) /\* {re.escape(group_name)} \*/'
    match = re.search(pattern, content)
    return match.group(1) if match else None

def main():
    project_file = 'PetSafety.xcodeproj/project.pbxproj'

    # Read project to find group UUIDs
    with open(project_file, 'r') as f:
        content = f.read()

    # Find UUIDs for groups
    services_uuid = find_group_uuid(content, 'Services')
    views_uuid = find_group_uuid(content, 'Views')
    components_uuid = find_group_uuid(content, 'Components')
    models_uuid = find_group_uuid(content, 'Models')

    print(f"Found group UUIDs:")
    print(f"  Services: {services_uuid}")
    print(f"  Views: {views_uuid}")
    print(f"  Components: {components_uuid}")
    print(f"  Models: {models_uuid}")
    print()

    if not all([services_uuid, views_uuid, components_uuid, models_uuid]):
        print("ERROR: Could not find all required group UUIDs")
        return

    # Files to add: (filename, relative_path, group_uuid)
    files_to_add = [
        ('NetworkMonitor.swift', 'Services/NetworkMonitor.swift', services_uuid),
        ('OfflineDataManager.swift', 'Services/OfflineDataManager.swift', services_uuid),
        ('SyncService.swift', 'Services/SyncService.swift', services_uuid),
        ('OfflineIndicator.swift', 'Views/Components/OfflineIndicator.swift', components_uuid),
    ]

    print("Adding files to Xcode project...")
    if add_files_to_xcode_project(project_file, files_to_add, {}):
        print("\n✅ Successfully added all files to Xcode project!")
        print("\nNOTE: The Core Data model (PetSafety.xcdatamodeld) needs to be added manually")
        print("      or you can open Xcode and use File > Add Files to add it.")
    else:
        print("\n❌ Failed to add files to project")

if __name__ == '__main__':
    main()
